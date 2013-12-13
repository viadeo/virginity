module Virginity

  # Helper methods to perform queries on lines in a DirectoryInformation instance
  #
  # query format: <tt>[group.][name][:value]</tt>
  #
  # examples:
  # * "FN" searches for FN-fields
  # * "FN:John Smith" searches for an FN-field with the value "John Smith"
  # * ":John Smith" searches for any field with the value "John Smith"
  # * "item1.:John Smith" searches for any field with the value "John Smith" and group item1
  module Query

    # if a query cannot be parsed an InvalidQuery is raised
    # the query-decoder expects correct input, it will not attempt to find errors or even correct them for you
    class InvalidQuery < Error; end

    GROUP = /#{Bnf::NAME}\./
    NAME = /#{Bnf::NAME}/
    SEMICOLON = /\;/
    COLON = /\:/
    def self.decode_query(query)
      scanner = StringScanner.new(query)
      # does the query start with a name that ends in a dot?
      if group = scanner.scan(GROUP)
        group.chomp!(".")
      end
      name = scanner.scan(NAME) # could be nil
      params = params(scanner)
      value = nil
      if scanner.skip(COLON)
        value = scanner.rest
      end
      [group, name, params, value]
    end

    COMMA = /,/
    EQUALS = /=/
    KEY = /#{Bnf::NAME}/
    PARAM_NAME = /((X|x)\-)?(\w|\-)+/
    PARAM_VALUE = /#{Bnf::PVALUE}/
    def self.params(scanner)
      return nil unless scanner.skip(SEMICOLON)
      params = []
      until scanner.check(COLON) or scanner.eos?  # <--- check of end of string! and *check* for colon
        key = scanner.scan(PARAM_NAME)
        raise InvalidQuery unless scanner.skip(EQUALS)
        begin
          if value = scanner.scan(PARAM_VALUE)
            params << Param.new(key, Param::decode_value(value))
          end
          break if scanner.skip(SEMICOLON) # after a semicolon, we expect key=(value)+
        end until scanner.skip(COMMA).nil? # a comma indicates another value (TYPE=HOME,WORK)
      end
      params
    end

    def query(query = "")
      group, name, params, value = Query::decode_query(query)
      lines.select do |line|
        # to_s is used here to match a nil-group to the empty-group-query: "."
        (group.nil? || group == line.group.to_s) &&
        (params.nil? || params.all? { |p| line.params.include? p }) &&
        (name.nil? || line.has_name?(name)) &&
        (value.nil? || value == line.raw_value)
      end
    end

    # return the first match for query q. By definition this is equivalent to query(q).first but it is faster.
    def first_match(query = "")
      group, name, params, value = Query::decode_query(query)
      lines.detect do |line|
        # to_s is used here to match a nil-group to the empty-group-query: "."
        (group.nil? || group == line.group.to_s) &&
        (params.nil? || params.all? { |p| line.params.include?(p) }) &&
        (name.nil? || line.has_name?(name)) &&
        (value.nil? || value == line.raw_value)
      end
    end

    def lines_with_name(name = "")
      lines.select do |line|
        line.has_name?(name)
      end
    end

    def line_matches_query?(line, q, v)
      raise ArgumentError, "query cannot be nil { #{q.inspect} => #{v.inspect} }?" if v.nil?
      case q
      when :name
        line.has_name?(v)
      when :raw_value
        v == line.raw_value
      when :text
        return false unless line.respond_to? :text
        v == line.text
      when :sha1
        return false unless line.respond_to? :sha1
        v == line.sha1
      when :group
        v == line.group
      when :values
        raise ArgumentError, "expected an array of values { #{q.inspect} => #{v.inspect} }?" unless v.is_a? Array
        if line.respond_to? :values
          if line.respond_to? :components # stuctured text, values are ordered and the lenght of the array is guaranteed to be correct.
            line.values == v
          else
            (line.values - v).empty?
          end
        else
          false
        end
      when :has_param
        # true if one param matches the array we feed it
        line.params.include? Param.new(v.first, v.last)
      when :has_param_with_key
        # true if one param matches the array we feed it
        line.params.any? { |p| p.has_key?(v) }
      when :has_type
        # true if one param matches the array we feed it
        line.params.include? Param.new('TYPE', v)
      when :params
        # all params match v, and no param is not matching
        raise NotImplementedError
      else
        raise ArgumentError, "what do you expect me to do with { #{q.inspect} => #{v.inspect} }?"
      end
    end

    def where(query = {})
      lines.select do |line|
        query.all? { |q,v| line_matches_query?(line, q, v) }
      end
    end

    def find_first(query = {})
      lines.detect do |line|
        query.all? { |q,v| line_matches_query?(line, q, v) }
      end
    end

    alias_method(:/, :query) #/# kate's syntax highlighter is (slightly) broken so I put a slash here
  end
end
