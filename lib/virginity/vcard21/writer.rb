require 'virginity/vcard21/base'

module Virginity
  module Vcard21
    module Writer # for Field


      class Vcard21Line

        class LineTooWide < Error; end

        # this is probably the correct way to see if we have non-ascii in ruby1.9
        # we duplicate every part of a content-line so that we safely can change values
        def initialize(group, name, params, value)
          @group = group.nil? ? nil : group.dup
          @name = name.dup
          @params = Param::deep_copy(params)
          if @params.any? {|p| p.key =~ ENCODING and p.value =~ /^b$/i }
            @params.delete_if {|p| p.key =~ ENCODING and p.value =~ /^b$/i }
            @params << Param.new("ENCODING","BASE64")
          end
          if qp?
            @value = EncodingDecoding::decode_quoted_printable(@value)
            @params.delete_if {|p| p.key =~ ENCODING and p.value =~ QUOTED_PRINTABLE }
          else
            @value = value.dup
          end
          @value = "2.1" if @name == "VERSION"
        end

        def inspect
          {:group => @group, :name => @name, :params => @params.join(', '), :value => @value}.inspect
        end

        LINE_TOO_LONG = /[^\n\r]{76,}/
        def line_too_wide_for21?(line)
          !(line =~ LINE_TOO_LONG).nil?
        end

        def qp?
          @params.any? { |p| Vcard21::qp_param?(p) }
        end

        def base64?
          @params.any? { |p| Vcard21::base64_param?(p) }
        end

        # FIXME there must be a better way to find non-ascii chars
        def non_ascii?
          @value.each_byte do |b|
            return true if b > 127
          end
          false
        end

#         NON_ASCII_CHAR = /^\u{0000}-\u{007F}/
#         def non_ascii?
#           if @value =~ NON_ASCII_CHAR
#             @params << Param.new("CHARSET","UTF-8")
#             @params << Param.new("ENCODING","QUOTED-PRINTABLE")
#             return
#           end
#         end

        # param = param-name "=" param-value *("," param-value)
        def params_to_s(options = {})
          return "" if @params.empty?
          if options[:vcard21_omit_type_if_knowntype]
            pv = @params.uniq.sort.map do |p|
              (p.key == "TYPE" and KNOWNTYPES.include? p.value) ? p.value : p.to_s
            end
            ";" + pv.join(";")
          else
            ";" + @params.uniq.sort.join(";")
          end
        end



        def pre_process_value!(options = {})
          encoding = @params.select {|p| p.key =~ ENCODING }
          raise "vCard author is confused, #{encoding.inspect}" if encoding.size > 1
          if encoding.empty?
            if non_ascii?
              @params << Param.new("CHARSET","UTF-8")
              @params << Param.new("ENCODING","QUOTED-PRINTABLE")
            elsif @value =~ /\r|\n/
              @params << Param.new("ENCODING","QUOTED-PRINTABLE")
            elsif line_too_wide_for21?(@value) # if the value part alone already is too wide
              @params << Param.new("ENCODING","QUOTED-PRINTABLE")
            end
          else
            case encoding.first.value
            when QUOTED_PRINTABLE, EIGHT_BIT, SEVEN_BIT, BASE64
              nil
            else
              raise "unexpected encoding #{encoding.first.inspect}"
            end
          end
        end

        def to_s(options = {})
          pre_process_value!(options)
          @params.uniq!
          line = [@group, @name].compact.join(".")
          line << params_to_s(options.merge({:vcard21_omit_type_if_knowntype => true}))
          line << ":"
          if qp?
            line << EncodingDecoding::encode_quoted_printable(@value, :initial_position => line.size) if qp?
          elsif base64?
            #Fixes::photo_folding_like_apple(@value, options.merge({:width => 70})) + "\r\n"
            # "\\0" is the matched string
            line << "\r\n" << @value.gsub(/.{70}/u, "\\0\r\n") << "\r\n"
          else
            line << @value
          end
          raise LineTooWide, "line_too_wide #{line.inspect}" if line_too_wide_for21?(line)
          line
        rescue LineTooWide => e
          return line if qp? # we did all we can, let's hope the phone can read this vcard
          @params << Param.new("ENCODING","QUOTED-PRINTABLE")
          retry
        end
      end

      def vcard21line
        if self.respond_to?(:text)
          Vcard21Line.new(@group, @name, @params, text) # we possibly want to reencode text as QP. With newlines and such
        else
          Vcard21Line.new(@group, @name, @params, @value)
        end
      end

      def encode21(options = {})
        vcard21line.to_s(options)
      end
    end
  end
end
