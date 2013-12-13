module Virginity

  class RelatedNames < BaseField
    include Params::Type
    include FieldValues::Text
    register_for "X-ABRELATEDNAMES"
  end


  class XAbLabel < BaseField
    ABLABEL = "X-ABLabel"
    register_for ABLABEL
    SAFE_LABELS = %w(HOME WORK FAX CELL PREF MAIN PAGER INTERNET VOICE)
    STRANGELABEL_MATCHER = /_\$!<(.*)>!\$_/
    STRANGE_LABELS = {}
    %w(HomePage Other Assistant Father Mother Parent Brother Sister Child Friend Spouse Partner Manager Anniversary).each do |v|
      STRANGE_LABELS[v.upcase] = v
    end
    STRANGE_LABELS.freeze
    #SAFECHARS = /^(.[^\"\;\:\,])*$/
    #ALREADYQOUTED = /^\"(.*?)\"$/

    def self.from_param(param, options = {})
      raise TypeError, "expected a Param with key == \"TYPE\"" unless param.key.upcase == "TYPE"
      from_text(param.value, options)
    end

    def to_param
      Param.new("TYPE", text)
    end

    def self.from_text(t, options = {})
      new(ABLABEL).tap do |label|
        label.text = t
        label.group = options[:group]
      end
    end

    def self.types_to_convert_to_xablabel(field)
      field.params('TYPE').reject do |type|
        SAFE_LABELS.include?(type.value)
      end
    end

    # returns an array of XAbLables
    def self.from_field(field)
      types_to_convert_to_xablabel(field).map { |t| from_param(t) }
    end

    def text
      if match = STRANGELABEL_MATCHER.match(@value)
        match[1].upcase
      else
        @value
      end
    end

    def text=(text)
      if x = STRANGE_LABELS[text.upcase]
        @value = "_$!<#{x}>!$_"
      else
        @value = text
      end
    end
  end


  class XAbDate < BaseField
    include FieldValues::Text
    include FieldValues::DateValue
    include Params::Type
    register_for "X-ABDATE"
  end


  class XAbAdr < BaseField
    include FieldValues::Text
    ABADR = "X-ABADR"
    register_for ABADR

    def self.from_param(param)
      raise TypeError unless param.is_a?(Param) and param.key.downcase == "x-format"
      from_text(param.value)
    end

    def self.from_text(t)
      new(ABADR, EncodingDecoding::encode_text(t))
    end

    def to_param
      Param.new("x-format", text)
    end
  end

end
