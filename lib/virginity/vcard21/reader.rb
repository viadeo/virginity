require 'virginity/vcard21/base'
require 'virginity/vcard21/parser'

module Virginity
  module Vcard21

    class ParseError < Error; end

    module Reader # for DirectoryInformation
      def from_vcard21(string)
        dirinfo = DirectoryInformation.new
        dirinfo.lines = lines_from_vcard21(string)
        dirinfo
      end

      # remove QUOTED-PRINTABLE-encoding
      def reencode_quoted_printable!(line)
        line[:params] ||= []
        line[:params].delete_if { |p| Vcard21::qp_param?(p) }
        # FIXME encoding. reencoding could fail because the characters are not encodable as text
        if line[:value].include?(";") # if the unencoded value contains ";" it's a list
          v = line[:value].split(";").map { |e| EncodingDecoding::decode_quoted_printable(e) }
          line[:value] = EncodingDecoding::encode_text_list(v, ";")
        elsif line[:value].include?(",")
          v = line[:value].split(",").map { |e| EncodingDecoding::decode_quoted_printable(e) }
          line[:value] = EncodingDecoding::encode_text_list(v, ",")
        else
          v = EncodingDecoding::decode_quoted_printable(line[:value])
          line[:value] = EncodingDecoding::encode_text(v)
        end
        line
      end

      def convert_base64_to_b!(line)
        line[:params] ||= []
        line[:params].delete_if { |p| Vcard21::base64_param?(p) }
        line[:params] << Param.new("ENCODING", "b")
        line
      end

      def convert_charsets!(line)
        line[:params] ||= []
        charset = line[:params].find { |p| p.key == "CHARSET" }
        line[:value] = line[:value].force_encoding(charset.value).encode
        line[:params].delete charset
        line
      end

      LATIN1 = "ISO-8859-1"
      def guess_charset_for_part!(s)
        s.force_encoding(Encoding::UTF_8) if s.encoding == Encoding::BINARY
        return s if s.valid_encoding?

        s = s.dup.force_encoding(LATIN1).encode
        raise Virginity::InvalidEncoding, "can't fix #{s.to_s.inspect}" unless s.valid_encoding?
      end

      def guess_charset!(line)
        line[:value] = guess_charset_for_part!(line[:value])
      end

      def line21_parts(string)
        parser = Vcard21::Parser.new(string+"\n")
        line = parser.parse_item
        fix_vcard21_line!(line)
        group = line[:groups] ? line[:groups].first : nil
        [group, line[:name], line[:params] || [], line[:value]]
      rescue
        raise ParseError, string.inspect
      end

      def read_21_line(string)
        group, name, params, value = line21_parts(string)
        ContentLine.new(name, value, params, group)
      end

      def fix_vcard21_line!(line)
        unless line[:params].nil?
          reencode_quoted_printable!(line) if line[:params].any? { |p| Vcard21::qp_param?(p) }
          convert_base64_to_b!(line) if line[:params].any? { |p| Vcard21::base64_param?(p) }
          convert_charsets!(line) if line[:params].any? { |p| p.key == "CHARSET" }
        end
        guess_charset!(line)
        if position = line[:value] =~ UNSUPPORTED_CONTROL_CHARS
          raise "unsupported control character in line #{line.inspect} at character #{position}: 0x#{line[:value][position].to_s(16)}"
        end
        line
      end

      UNSUPPORTED_CONTROL_CHARS = /\x01|\x02|\x03|\x04|\x05|\x06|\x07|\x08|\x0e|\x0f|\x10|\x11|\x12|\x13|\x14|\x15|\x16|\x17|\x18|\x19|\x1a|\x1b|\x1c|\x1d|\x1e|\x1f|\x7f/

      def lines_from_vcard21(string, options = {})
        lines = Vcard21::Parser.new(string, options).parse!
        lines.each { |line| fix_vcard21_line!(line) }
        lines.map do |line|
          group = line[:groups].nil? ? nil : line[:groups].first
          ContentLine.new(line[:name], line[:value], line[:params] || [], group, :no_deep_copy => true)
        end
      end
    end

  end
end
