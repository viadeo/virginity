require 'virginity/encoding_decoding'
require 'virginity/dir_info/param'

module Virginity

  # raised when merging will fail
  class MergeError < Error; end

  # rfc 2425 describes a content line as this:
  #   contentline  = [group "."] name *(";" param) ":" value CRLF
  # See also: DirectoryInformation
  #
  # A ContentLine is a tuple of one group (optional), a name, zero or more parameters and a value.

  # Type names and parameter names are case insensitive (e.g., the type
  # name "fn" is the same as "FN" and "Fn"). Parameter values MAY be case
  # sensitive or case insensitive, depending on their definition.
  class ContentLine
    attr_accessor :group, :name, :value
    attr_writer :params
    alias_method :raw_value, :value

    extend Encodings
    include Encodings

    # create a ContentLine by specifying all its parts
    def initialize(name = "X-FOO", value = nil, params = [], group = nil, options = {})
      @group = group
      @name = name.to_s
      @params = options[:no_deep_copy] ? (params) : Param.deep_copy(params)
      @value = value.to_s
    end

    # decode a line
    def self.parse(line = "X-FOO:bar")
      group, name, params, value = line_parts(line.to_s)
      # optimization: since params is deep_copied, constructing many objects and we know for certain that params can safely be used without copying, we put it in later.
      new(name, value, params, group, :no_deep_copy => true)
    end

    class << self
      alias_method :from_line, :parse
    end

    # the combination of two content lines
    # This method will raise a MergeError if names, groups or values are conflicting
    def self.merger(left, right)
      raise MergeError, "group, #{left.group} != #{right.group}" unless left.group == right.group or left.group.nil? or left.group.nil?
      raise MergeError, "name, #{left.name} != #{right.name}" unless left.has_name?(right.name)
      raise MergeError, "value, #{left.raw_value} != #{right.raw_value}" unless left.raw_value == right.raw_value
      ContentLine.new(left.name, left.raw_value, (left.params + right.params).uniq, left.group || right.group)
    end

    # combine with new values from another line.
    # This method will raise a MergeError if names, groups or values are conflicting
    def merge_with!(other)
      raise MergeError, "group, #{group} != #{other.group}" unless group == other.group or group.nil? or other.group.nil?
      raise MergeError, "name, #{name} != #{other.name}" unless has_name?(other.name)
      raise MergeError, "value, #{raw_value} != #{other.raw_value}" unless raw_value == other.raw_value
      self.group = group || other.group
      self.params = (params + other.params).uniq
      self
    end

    GROUP_DELIMITER = "."
    COLON_CHAR = ":"
    def encode #(options = {})
      line = ""
      line << group << GROUP_DELIMITER unless group.nil?
      line << name << params_to_s << COLON_CHAR << raw_value
    end
    alias_method :to_s, :encode

    def pretty_print(q)
      q.text({:line => { group: @group, name: @name, params: params_to_s, value: @value }}.to_yaml)
    end

    def has_name?(name)
      @name.casecmp(name) == 0
    end

    # if key is given, return only matching parameters
    def params(key = nil)
      if key.nil?
        @params
      else
        @params.select { |param| param.has_key?(key) } # case insensitive by design!
      end
    end

    # convenience method to grab only the values of the parameters (without the keys)
    def param_values(key = nil)
      params(key).map { |param| param.value }
    end

    def ==(other)
      group == other.group &&
        has_name?(other.name) &&
        params == other.params &&
        raw_value == other.raw_value
    end

    def <=>(other)
      str_diff(group, other.group) || str_diff(name, other.name) || (to_s <=> other.to_s)
    end

    def hash
      [group, name, params, raw_value].hash
    end

    def eql?(other)
      group == other.group &&
        has_name?(other.name) &&
        params == other.params &&
        raw_value ==  other.raw_value
    end

    GROUP = /#{Bnf::NAME}\./
    NAME = /#{Bnf::NAME}/
    # decode a contentline, returns the four parts [group, name, params, value]
    def self.line_parts(line)
      scanner = StringScanner.new(line)
      if group = scanner.scan(GROUP)
        group.chomp!(".")
        group
      end
      name = scanner.scan(NAME)
      name.upcase! # FIXME: names should be case insensitive when compared... only when compared
      [group, name, Param::scan_params(scanner), scanner.rest]
    rescue InvalidEncoding
      raise
    rescue => e
      raise InvalidEncoding, "#{scanner.string.inspect}, at pos #{scanner.pos} (original error: #{e})"
    end

    def params_to_s
      Param::params_to_s(params)
    end

  private
    def str_diff(left, right)
      diff = (left <=> right)
      diff == 0 ? nil : diff
    end
  end
end
