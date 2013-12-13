module Virginity
  module Encodings

    def binary?(s)
      s.encoding == Encoding::BINARY
    end

    def to_binary(s)
      s.dup.force_encoding(Encoding::BINARY)
    end

    def to_ascii(s)
      s.dup.force_encoding(Encoding::ASCII)
    end

    def to_default(s)
      s.encode
    end

    def to_default!(s)
      s.encode!
    end

    def verify_utf8ness(string)
      if string.encoding == Encoding::UTF_8 || string.encoding == Encoding::US_ASCII
        unless string.valid_encoding?
          # puts "*"*100, "incorrectly encoded String", string, "*"*100
          raise InvalidEncoding, "incorrectly encoded String"
        end
      else
        raise InvalidEncoding, "expected UTF-8 or ASCII"
      end
    end

  end
end
