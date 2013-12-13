module Virginity

  class Error < StandardError; end
  class InvalidEncoding < Error; end

  module EncodingDecoding
    extend Encodings

    # VALUE-CHAR   = WSP / VCHAR / NON-ASCII
    WSP = [0x20, 0x09] # WSP = SP / HTAB
    VCHAR = 0x21..0x7E # VCHAR =  %x21-7E ; visible (printing) characters
    NONASCII = 0x80..0xFF # NON-ASCII = %x80-FF

    CR_AND_LF = /\r\n/
    CR = "\r"
    LF = "\n"
    def self.decode_quoted_printable(text)
      text.gsub(CR_AND_LF, LF).gsub(/\=([0-9a-fA-F])?\n\s+([0-9a-fA-F])/, "=\\1\\2").unpack('M*').first
    end

    QP_ALSO_ENCODE = "\x0A\x20"
    def self.encode_quoted_printable(text, options = {})
      options[:also_encode] ||= QP_ALSO_ENCODE
      # special_chars = /[\t ](?:[\v\t ]|$)|[=\x00-\x08\x0B-\x1F\x7F-\xFF#{options[:also_encode]}]/
      special_chars = /[=\x00-\x08\x0B-\x1F\x7F-\xFF#{options[:also_encode]}]/n
      encoded = to_binary(text).gsub(special_chars) do |char|
        char[0 ... -1] + "=%02X" % char[-1].ord
      end
      fold_quoted_printable(encoded, options[:width] || 76, options[:initial_position])
    end

    QPCHAR = /[^=]|=[\dABCDEF]{2}/
    QPFOLD = "=\r\n" # only vCard 2.1 uses encode_quoted_printable so we always use windows line endings
    def self.fold_quoted_printable(qp_text, width = 76, initial_position = 0)
      return qp_text unless width > 5
      pos = initial_position.to_i
      scanner = StringScanner.new(qp_text)
      folded = ""
      while !scanner.eos?
        char = scanner.scan(QPCHAR)
        charsize = char.size
        if pos + charsize > width - 3
          folded << QPFOLD
          pos = 0
        end
        folded << char
        pos += charsize
      end
      folded
    end


    def self.normalize_newlines!(text)
      text.gsub!(/\r?\n|\r/, "\n")
    end

    # "text": The "text" value type should be used to identify values that
    # contain human-readable text. The character set and language in which
    # the text is represented is controlled by the charset content-header
    # and the language type parameter and content-header.
    #
    # A formatted text line break in a text value type MUST be represented
    # as the character sequence backslash (ASCII decimal 92) followed by a
    # Latin small letter n (ASCII decimal 110) or a Latin capital letter N
    # (ASCII decimal 78), that is "\n" or "\N".
    #
    # TODO options for saving to ascii (convert to quoted printable) or storing plain utf-8
    ENCODED_LF = "\\n"
    CRLF = CR + LF
    BACKSLASH = "\\"
    COMMA = ","
    SEMICOLON = ";"
    STUFF_TO_ENCODE = /[\n\\\,\;]/
    STUFF_NOT_TO_ENCODE = %r{[^\n\\\,\;]*}
    def self.encode_text(text)
      raise "#{text.inspect} must be a String" unless text.is_a? String
      normalize_newlines!(text)
      encoded = ""
      s = StringScanner.new(text)
      while !s.eos?
        encoded << s.scan(STUFF_NOT_TO_ENCODE)
        # 5.8.4 Backslashes, newlines, and commas must be encoded.
        case x = s.scan(STUFF_TO_ENCODE)
        when LF
          encoded << ENCODED_LF
        when BACKSLASH, COMMA, SEMICOLON
          # RFC2426 tells us to encode ":" too, which is needed for structured text fields
          encoded << BACKSLASH << x
        end
      end
      encoded
    end

    def self.decode_text(text)
      text.gsub(/\\(.)/) { $1.casecmp('n') == 0 ? LF : $1 }
    end

    def self.encode_text_list(list, separator = COMMA)
      list.map { |value| encode_text(value) }.join(separator)
    end

#     # TODO: port to C someday
      # This is the old simple implementation that is easy to port to another language
      # this can be a lot faster if we don't create a new string object for each char
#     def self.decode_text_list(text_list, separator = COMMA)
#       strings = []
#       state = :normal # there are two states: :normal and :escaped
#       string = ""
#       text_list.each_char do |char|
#         if state == :escaped
#           string << (%w(n N).include?(char) ? LF : char)
#           state = :normal
#         else
#           case char
#           when BACKSLASH
#             state = :escaped
#           when separator
#             strings << string
#             string = ""
#           else
#             string << char
#           end
#         end
#       end
#       strings << string
#       strings
#     end


    NON_ESCAPE_OR_SEPARATOR_REGEXP = {}
    def self.non_escape_or_separator_regexp(separator)
      NON_ESCAPE_OR_SEPARATOR_REGEXP[separator] ||= %r{[^\\#{separator}\\\\]*}
    end

    def self.decode_text_list(text_list, separator = COMMA)
      not_special = non_escape_or_separator_regexp(separator)
      list = []
      text = ""
      s = StringScanner.new(text_list)
      while !s.eos?
        text << s.scan(not_special)
        break if s.eos?
        case s.getch
        when BACKSLASH
          char = s.getch
          # what do I do when char is nil? ignore the backslash too? I don't know...
          raise InvalidEncoding, "text list \"#{text_list}\" ends after escape char" if char.nil?
          text << (char.casecmp('n') == 0 ? LF : char)
        when separator
          list << text
          text = ""
        else
          raise InvalidEncoding, "read #{s.matched.inspect} at #{s.pos} in #{s.string.inspect} (#{s.string.size}) using #{not_special.inspect}"
        end
      end
      list << text
      list
    end

    # Compound type values are delimited by a field delimiter, specified by the SEMI-COLON character (ASCII decimal 59). A SEMI-COLON in a component of a compound property value MUST be escaped with a BACKSLASH character (ASCII decimal 92).
    #
    # Lists of values are delimited by a list delimiter, specified by the COMMA character (ASCII decimal 44). A COMMA character in a value MUST be escaped with a BACKSLASH character (ASCII decimal 92).
    #
    # This profile supports the type grouping mechanism defined in [MIME-DIR]. Grouping of related types is a useful technique to communicate common semantics concerning the properties of a vCard.
    def self.decode_structured_text(value, size, separator = SEMICOLON)
      list = decode_text_list(value, separator)
      list << "" while list.size < size
      list.pop while list.size > size
      list
    end

    def self.encode_structured_text(list, separator = SEMICOLON)
      encode_text_list(list, separator)
    end

  end
end
