module Virginity
  module FieldValues

    module Text
      def text
        EncodingDecoding::decode_text(@value)
      end

      def text=(s)
        @params.delete_if { |p| p.key == "ENCODING" }
        @value = EncodingDecoding::encode_text(s)
      end

      def reencode!
        self.text = text
      end

      def value_to_xml
        xml_element("text", text.strip)
      end
    end
  end
end
