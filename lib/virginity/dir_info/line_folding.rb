require 'strscan'
$KCODE = 'U' unless defined? Encoding::UTF_8

module Virginity

  module LineFolding
    LINE_ENDING = /\r\n|\n|\r/ # the order is important!
    FOLD = /(#{LINE_ENDING})[\t\ ]/ # we accept unix-newlines and mac-newlines too (spec says only windows newlines, \r\n, are okay)

    # 5.8.1.  Line delimiting and folding.
    # A logical line MAY be continued on the next physical line anywhere between two characters by inserting a CRLF immediately followed by a single white space character (space, ASCII decimal 32, or horizontal tab, ASCII decimal 9).  At least one character must be present on the folded line. Any sequence of CRLF followed immediately by a single white space character is ignored (removed) when processing the content type.
    def self.unfold(card)
      card.gsub(FOLD, '')
    end

    def self.unfold_and_split(string)
      unfold(string).split(LINE_ENDING)
    end

    # TODO: option to encode with "\r\n" instead of "\n"?
    # not multibyte-safe but very safe for ascii
    def self.fold_ascii(card, width = 75)
      return card unless width > 0
      # binary should already be encoded to a width that is smaller than width
      card.gsub(/.{#{width}}/, "\\0\n ") # "\\0" is the matched string
    end

    # utf-8 safe folding:
    # TODO: I think this is a good candidate to be ported to C
    def self.fold(card, width = 75)
      return card unless width > 0
      # binary fields should already be encoded to a width that is smaller than width
      scanner = StringScanner.new(card)
      folded = ""
      line_pos = 0
      while !scanner.eos?
        char = scanner.getch
        charsize = char.size
        if line_pos + charsize > width
          folded << "\n "
          line_pos = 0
        end
        folded << char
        char == "\n" ? line_pos = 0 : line_pos += charsize
      end
      folded
    end

    # Content lines SHOULD be folded to a maximum width of 75 octets, excluding the
    # line break.  Multi-octet characters MUST remain contiguous.
    # So, we're doing it wrong, we should count octets... bytes.

    # This is way faster than the method above and unicode-safe
    # it is slightly different: it does not count bytes, it counts characters
    def self.fold(card)
      card.gsub(/.{75}(?=.)/, "\\0\n ")  # "\\0" is the matched string
    end

  end
end
