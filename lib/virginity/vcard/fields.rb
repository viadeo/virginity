require "virginity/vcard/field"
require "virginity/vcard/field/params"
require "base64"

module Virginity

  # BEGIN or END
  #
  # We don't do much with them
  class BeginEnd < BaseField
    include FieldValues::CaseInsensitiveValue
    # value MUST be "VCARD"
    register_for :BEGIN, :END
  end


  class Profile < BaseField
    register_for :PROFILE
  end


  # Text fields, see FieldValues::Text for safe encoding/decoding methods
  class TextField < BaseField
    include FieldValues::Text
    register_for :CLASS, :FN, :LABEL, :MAILER, :NOTE, :PRODID, :ROLE, 'SORT-STRING', :TITLE, :UID, :VERSION, :'X-PHONETIC-LAST-NAME', :'X-PHONETIC-FIRST-NAME'
  end


  # A BDAY in a vCard can be a free form text-value or a date. This class provides methods for both cases.
  class Birthday < BaseField
    include FieldValues::Text
    include FieldValues::DateValue
    register_for :BDAY
  end


  class Anniversary < BaseField
    include FieldValues::Text
    include FieldValues::DateValue
    register_for "X-ANNIVERSARY"
  end


  # Instant messaging fields are defined in rfc 2427. They have a scheme and an address. If an IMPP is not 'clean' one can still get/set the value by using the methods from FieldValues::Text and FieldValues::Uri
  class Impp < BaseField
    include FieldValues::Text
    include FieldValues::Uri
    include Params::Type
    register_for :IMPP
#       include LocationHandling
#       include PurposeHandling
#       include PreferenceHandling
#       PURPOSE_SETS = { "personal" => "Personal", "business" => "Business" }
#       HUMAN_DESCRIPTION = "instant messaging"

#       def initialize(content_line=ContentLine.new("IMPP:"))
#         super
#         @cline.name = "IMPP"
#       end

    def scheme
      # every piece of text before the first colon, if there is a colon present
      text.match(/^(.*?):/) # Note the use of "*?" for non greedy matching of the colon!
      $1 || ""
    end

    def address
      # everything after the first colon if that colon is present, otherwise the whole text
      text.match(/^.*?:(.*)$|^(.*)$/)
      $1 || $2
    end

    def scheme=(s)
      self.text = "#{s}:#{address}"
    end

    def address=(s)
      self.text = "#{self.scheme}:#{s}"
    end

    def raw_value
      scheme.empty? && address.empty? ? "" : @value
    end
  end


  # OS X AddressBook does not use the IMPP fields. Instead Apple chose to use their own proprietary format. This format is handles by CustomImField
  class CustomImField < BaseField
    include FieldValues::Text
    PROTOCOL_TRANSLATION_TABLE = {
      :aim => "X-AIM",
      :msn => "X-MSN",
      :ymsgr => "X-YAHOO",
      :skype => "X-SKYPE",
      :qq => "X-QQ",
      :gtalk => "X-GOOGLE TALK",
      :icq => "X-ICQ",
      :xmpp => "X-JABBER",
    }
    PROTOCOL_TRANSLATION_TABLE.values.each { |protocol| register_for protocol }
    PROTOCOL_TRANSLATION_INVERSE_TABLE = Hash[PROTOCOL_TRANSLATION_TABLE.map { |k, v| [v, k] }]

    # convert a standard IMPP field to a Custom IM field. Only schemes defined in PROTOCOL_TRANSLATION_TABLE are supported.
    def self.from_impp(impp)
      nm = PROTOCOL_TRANSLATION_TABLE[impp.scheme.to_sym]
      raise "unknown scheme #{impp.scheme} for #{impp.text.inspect}" if nm.nil?
      x = Field.parse("#{nm}:")
      x.params = Param::deep_copy(impp.params)
      x.text = impp.address
      x
    end

    def protocol
      PROTOCOL_TRANSLATION_INVERSE_TABLE[name]
    end

    # convert to a standard IMPP field
    def to_impp
      impp = Field.parse("IMPP:")
      impp.params = Param::deep_copy(@params)
      impp.text = "#{protocol}:#{text}"
      impp
    end
  end


  # handle ORG fields.
  #
  # An Org has an orgname, a unit1 and a unit2. We stick to this simple
  # definition for now since it is widely used. The vCard specs seem to
  # specify an unlimited amount of units
  class Org < BaseField
    register_for :ORG
    include FieldValues::StructuredText.define([:orgname, :unit1, :unit2])

    def shortened
      [orgname, unit1, unit2].join(" ").strip
    end

#       def ==(other)
#         super ||
#           has_name?(other.name) &&
#           values == other.try(:values) && self.class === other && self.group == other.group
#       end
  end


  # SeparatedField handles an array of text values
  class SeparatedField < BaseField
    include FieldValues::SeparatedText
    register_for :CATEGORIES, :NICKNAME

    def unpacked
      values.map do |text|
        self.class.new(name, EncodingDecoding::encode_text_list([text]), params, group)
      end
    end
  end


  # telephone number
  #
  # provides the easy getter/setter #number and generators for random numbers
  class Tel < BaseField
    include FieldValues::Text
    include Params::Type
    # include Params::Type::Preference
    register_for :TEL
    COMPARISON_REGEX = /[^\+\*\#\/\,\w]/u # anything that is NOT a plus, a star, a hash, a slash, a comma, or 0-9/a-z/A-Z is insignificant

    alias_method :number, :text
    alias_method :number=, :text=

    def self.random_number(length = 10)
      # (1..length).map { rand(10).to_s }.join
      # only 555-0100 through 555-0199 are now specifically reserved for fictional use
      random_part = 100 + (rand(99) + 1)
      "555-0#{random_part}"
    end

    def self.at_random
      new("TEL", random_number)
    end

    def significant_chars
      # it's a phone number (but people could store alphanumeric stuff here) so I opt to remove all dashes and spaces
      # I leave the plus since we don't know with what prefix to replace it with, see: http://en.wikipedia.org/wiki/List_of_international_call_prefixes
      number.gsub(COMPARISON_REGEX, "")
    end
    alias_method :normalized_number, :significant_chars

  end


  class Email < BaseField
    include FieldValues::Text
    include Params::Type
    register_for :EMAIL
    alias_method :address, :text
    alias_method :address=, :text=
  end


  class Adr < BaseField
    include FieldValues::StructuredText.define([:pobox, :extended, :street, :locality, :region, :postal_code, :country])
    include Params::Type
    register_for :ADR
    NAME = "ADR"
  end


  class Url < BaseField
    include FieldValues::Text
    include FieldValues::Uri
    # URLs officialy don't have TYPE params,
    # but everyone and their dog thinks they do.
    # So we decided to support them too.
    # Conclusion: no-one reads the RFC
    include Params::Type
    register_for :URL
  end


  class Name < BaseField
    PARTS = %w(family given additional prefix suffix)
    include FieldValues::StructuredText.define(PARTS)
    register_for :N
  end


  class Photo < BaseField
    include FieldValues::Text
    include FieldValues::Binary
    include FieldValues::Uri
    register_for :LOGO, :PHOTO

    def is_binary?
      @params.detect {|p| p.key == "ENCODING" and p.value =~ /B/i }
    end

    def is_url?
      !is_binary?
    end
  end


  class Sound < BaseField
    include FieldValues::Binary
    include FieldValues::Text
    include FieldValues::Uri
    register_for :SOUND
  end


  class Key < BaseField
    include FieldValues::Binary
    include FieldValues::Text
    register_for :KEY
  end

  class Gender < BaseField
    register_for :GENDER
    PARTS = %w(sex identity)
    include FieldValues::OptionalStructuredText.define(PARTS)

    {male: 'M', female: 'F', other: 'O', none: 'N', unknown: 'U'}.each do |name, letter|
      class_eval <<-RUBY
      def #{name}?
        sex == "#{letter}"
      end

      def #{name}=(v)
        raise "Only true is acceptable" unless v
        self.sex = "#{letter}"
      end
      RUBY
    end

    def neither?
      sex !~ /^[MFNOU]$/
    end
  end

end
