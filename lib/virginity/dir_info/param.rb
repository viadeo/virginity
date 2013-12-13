module Virginity

  # A directory information parameter is basically a key-value pair.
  # An instance of this class represents such a pair. It can deal with comparison and encoding. The class contains some methods to deal with lists of parameters
  # Param keys are case insensitive
  class Param
    attr_reader :key
    attr_accessor :value

    def initialize(key, value)
      self.key = key
      @value = value.to_s
    end

    # convenience method, the same as calling Param.new("TYPE", value)
    def self.type(value)
      new('TYPE', value)
    end

    def self.pref
      new('TYPE', 'PREF')
    end

    # convenience method, the same as calling Param.new("CHARSET", value)
    def self.charset(value)
      new('CHARSET', value)
    end

    # convenience method, the same as calling Param.new("ENCODING", value)
    def self.encoding(value)
      new('ENCODING', value)
    end

    # convenience method, the same as calling Param.new("ETAG", value)
    def self.etag(value)
      new('ETAG', value)
    end

    def to_s
      "#{@key}=#{escaped_value}"
    end
    alias_method :inspect, :to_s

    # param-name = x-name / iana-token
    # iana-token   = 1*(ALPHA / DIGIT / "-")
    #              ; identifier registered with IANA
    PARAM_NAME_CHECK = /^((X|x)\-)?(\w|\-)+$/
    def key=(key)
      raise "Invalid param-key: #{key.inspect}" unless key =~ PARAM_NAME_CHECK
      @key = key.upcase
    end

    def hash
      [@key, @value].hash
    end

    def eql?(other)
      other.is_a?(Param) && has_key?(other.key)&& @value == other.value
    end

    def has_key?(other_key)
      @key.casecmp(other_key) == 0
    end

    # NB. Other doesn't necessarily have to be a Param
    def ==(other)
      has_key?(other.key) && @value == other.value
    rescue
      false
    end

    def <=>(other)
      if has_key?(other.key)
        @value <=> other.value
      else
        @key <=> other.key
      end
    end

    # A semi-colon in a property parameter value must be escaped with a Blackslash character.
    # commas too I think, since these are used to separate the param-values
    #     param-value  = ptext / quoted-string
    #     ptext  = *SAFE-CHAR
    #     SAFE-CHAR    = WSP / %x21 / %x23-2B / %x2D-39 / %x3C-7E / NON-ASCII
    #        ; Any character except CTLs, DQUOTE, ";", ":", ","
    #     quoted-string = DQUOTE *QSAFE-CHAR DQUOTE
    #        QSAFE-CHAR   = WSP / %x21 / %x23-7E / NON-ASCII
    #       ; Any character except CTLs, DQUOTE
    ESCAPE_CHARS = /\\|\;|\,|\"/
    LF = "\n"
    ESCAPED_LF = "\\n"
    ESCAPE_CHARS_WITH_LF = /\\|\;|\,|\"|\n/
    ESCAPE_HASH = {
      '\\' => '\\\\',
      ';' => '\;',
      ',' => '\,',
      '"' => '\"',
      "\n" => '\n'
      }
    def escaped_value
      if @value =~ ESCAPE_CHARS_WITH_LF
        # put quotes around the escaped string
        "\"#{@value.gsub(ESCAPE_CHARS) { |char| "\\#{char}" }.gsub(LF, ESCAPED_LF)}\""
#         "\"#{@value.gsub(ESCAPE_CHARS_WITH_LF, ESCAPE_HASH)}\"" # ruby1.9
      else
        @value
      end
    end

    def self.decode_value(val)
      if Bnf::QUOTED_STRING =~ val
        EncodingDecoding::decode_text($2)
      else
        val
      end
    end

    # encodes an array of params
    def self.simple_params_to_s(params)
      return "" if params.empty?
      ";" + params.uniq.sort.join(";")
    end

    # encodes an array of params
    # param = param-name "=" param-value *("," param-value)
    def self.params_to_s(params)
      return "" if params.empty?
      s = []
      params.map {|p| p.key }.uniq.sort!.each do |key|
        values = params.select {|p| p.has_key? key }.map {|p| p.escaped_value }.uniq.sort!
        s << "#{key}=#{values.join(",")}"
      end
      ";#{s.join(";")}"
    end

    # encodes an array of params
    def self.params_to_s(params)
      return "" if params.empty?
      s = ""
      params.map { |p| p.key }.uniq.sort!.each do |key|
        values = params.select {|p| p.has_key? key }.map {|p| p.escaped_value }.uniq.sort!
        s << ";#{key}=#{values.join(",")}"
      end
      s
    end

    COLON = /:/
    SEMICOLON = /;/
    COMMA = /,/
    EQUALS = /=/
    KEY = /#{Bnf::NAME}/
    PARAM_NAME = /((X|x)\-)?(\w|\-)+/
    PARAM_VALUE = /#{Bnf::PVALUE}/

    BASE64_OR_B = /^(BASE64)|(B)$/i
    XSYNTHESIS_REF = /^X-Synthesis-Ref\d*$/i

    # scans all params at the given position from a StringScanner including the pending colon
    def self.scan_params(scanner)
      unless scanner.skip(SEMICOLON)
        scanner.skip(COLON)
        return []
      end
      params = []
      until scanner.skip(COLON) # a colon indicates the end of the paramlist
        key = scanner.scan(PARAM_NAME)
        unless scanner.skip(EQUALS)
          # it's not a proper DirInfo param but nevertheless some companies (Apple) put vCard2.1 shorthand params without a key in they vCard3.0. Therefore we include support for these special cases.
          case key
          when Vcard21::QUOTED_PRINTABLE
            params << Param.new('ENCODING', key)
          when BASE64_OR_B
            params << Param.new('ENCODING', 'B')
          when XSYNTHESIS_REF
            # we ignore this crap.
          when *Vcard21::KNOWNTYPES
            params << Param.new('TYPE', key)
          else
            raise InvalidEncoding, "encountered paramkey #{key.inspect} without a paramvalue"
          end
        end
        key.upcase!
        begin
          if value = scanner.scan(PARAM_VALUE)
            params << Param.new(key, Param::decode_value(value))
          end
          break if scanner.skip(SEMICOLON) # after a semicolon, we expect key=(value)+
        end until scanner.skip(COMMA).nil? # a comma indicates another values (TYPE=HOME,WORK)
      end
      params
    rescue InvalidEncoding
      raise
    rescue => e
      raise InvalidEncoding, "#{scanner.string.inspect} at character #{scanner.pos}\noriginal error: #{e}"
    end

    def self.params_from_string(string)
      scan_params(StringScanner.new(string))
    end

    def self.deep_copy(paramlist)
      return [] if paramlist.nil? or paramlist.empty?
      # params_from_string(simple_params_to_s(paramlist)) # slower
      Marshal::load(Marshal::dump(paramlist)) # faster
    end

  end # class Param
end
