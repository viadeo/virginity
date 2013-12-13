require "virginity/vcard/fields"

module Virginity

  class Vcard < DirectoryInformation
    # A Vcard-wrapper that deals with the the fields N, FN and NICKNAME.
    #
    # You will probably use it like this:
    #   v = Vcard.new
    #   v.name.given = "Bert"
    #   puts v
    #
    # There are undocumented methods for getting and setting: prefix, given, additional, family, and suffix.
    class NameHandler
      # takes a Vcard object or a String
      def initialize(vcard)
        if vcard.is_a? Vcard
          @vcard = vcard
        else
          @vcard = Vcard.from_vcard(vcard.to_s)
        end
      end

      # formatted name
      def to_s
        fn.text
      end
      alias_method :formatted, :to_s

      # regenerate the formatted name (that is the FN field)
      def reset_formatted!
        @vcard.delete(*@vcard.lines_with_name("FN"))
        fn.text
      end

      # generate a FN field using the following fields
      # n > nickname > org > email > impp > tel
      def generate_fn(options = {})
        nfield = n
        g = nfield.given.empty? ? nil : nfield.given
        f = nfield.family.empty? ? nil : nfield.family
        unless [g, f].compact.empty?
          if options[:include_nickname]
            nick = @vcard.nicknames.empty? ? nil : "\"#{@vcard.nicknames.first.values.first}\""
            [g, nick, f].compact.join(" ")
          elsif options[:complete_name]
            prefix = nfield.prefix.empty? ? nil : nfield.prefix
            additional = nfield.additional.empty? ? nil : nfield.additional
            suffix = nfield.suffix.empty? ? nil : nfield.suffix
            [prefix, g, additional, f, suffix].compact.join(" ")
          else
            [g, f].compact.join(" ")
          end
        else
          if not @vcard.nicknames.empty?
            nicknames.first
          elsif @vcard.organisations.first
            @vcard.organisations.first.values.first
          elsif @vcard.emails.first
            @vcard.emails.first.address
          elsif @vcard.impps.first
            @vcard.impps.first.address
          elsif @vcard.telephones.first
            @vcard.telephones.first.number
          else
            ""
          end
        end
      end

      # generate the fn using the complete name including prefix, additional parts and suffix
      def complete
        generate_fn(:complete_name => true)
      end

      # add a fn if it's not there (since it is required by the vCard specs) and return it
      def fn
        @vcard.lines_with_name("FN").first || @vcard.add_field("FN:#{EncodingDecoding::encode_text(generate_fn)}")
      end

      # add a n if it's not there (since it is required by the vCard specs) and return it
      def n
        @vcard.lines_with_name("N").first || @vcard.add_field("N:;;;;")
      end

      Name::PARTS.each do |part|
        class_eval <<-end_class_eval
          def #{part}
            n.#{part}
          end

          def #{part}=(value)
            return value if n.#{part} == value
            n.#{part} = value
            reset_formatted!
            value
          end
        end_class_eval
      end

      # are all parts of the N field empty? ("N:;;;;")
      def empty?
        Name::PARTS.all? { |part| send(part).empty? }
      end

      # an array with all nicknames
      def nicknames
        @vcard.nicknames.map {|n| n.values.to_a }.flatten
      end

      def add_nickname(nick)
        @vcard << SeparatedField.new("NICKNAME", EncodingDecoding::encode_text_list([nick]))
        reset_formatted!
        nick
      end

      def remove_nickname(nick)
        @vcard.nicknames.each do |nickname|
          nickname.values.delete(nick)
          @vcard.delete nickname if nickname.raw_value.empty? # the singular 'value' is meant here, don't change it to values!
        end
        reset_formatted!
        nick
      end

      def has_nickname?(nick)
        @vcard.nicknames.any? { |nickname| nickname.values.include?(nick) }
      end

      # merge this name with other_name; conflicting parts will raise a MergeError
      #
      # if the option :simple_name_resolving is true we choose the value in this name instead of raising an error. Parts that are not present in self will be filled in with the value from other_name
      def merge_with!(other_name, options = {})
        Name::PARTS.each do |part|
          own, his = send(part).rstrip, other_name.send(part).rstrip
          if own.empty?
            send "#{part}=", his
          elsif his.empty? or own == his
            # then nothing needs to be done
          else
            # :simple_name_resolving means keep our own name, don't take over his. iow: do nothing
            unless options[:simple_name_resolving]
              raise MergeError, "#{part} name is different: '#{own}' and '#{his}'"
            end
          end
        end
        self
      end
    end
  end
end
