require 'virginity/vcard21/base'

module Virginity
  module Vcard21
    class Parser
      include Virginity::Encodings

      def initialize(input, options = {})
        @input = StringScanner.new(input)
        @options = options
      end

      def pr(s)
        puts "#{@input.pos}:\t#{@input.peek(40).inspect}\t#{s}"
      end

      def parse!
        parse_start or raise ParseError, 'error parsing vCard2.1'
      end

      #
      # helpers
      #

      def rollback(pos)
        @input.pos = pos
        nil
      end

      def try(method)
        pos = @input.pos
        catch :rollback do
          return (method.call or throw :rollback)
        end
        rollback(pos)
      end

      def star(method)
        list = []
        until (result = try(method)).nil? do
          list << result
        end
        list
      end

      def one_star(method)
        head = try(method) or return nil
        [head] + star(method)
      end

      #
      # parsing differently encoded and folded strings
      #

      def parse_folded_literal(literal)
        # pr "parse_literal(#{literal.inspect})@#{@input.pos}".white
        success = true
        literal = unescape_literal(literal)
        literal.split(//).each do |ch|
          input = @input.get_byte
          input = parse("'\n' one_ws") if input == "\r" # CRLF followed by LWSP needs to be regarded as LWSP == Linear White Space
          # pr "#{ch.inspect}==#{input.inspect}?".white
          literal << input
          success &= (ch == input)
        end
        success ? literal : nil
      end


#       def parse_folded_literal(literal)
#         exp = /#{literal.split(//).map {|s| "#{s}(=\r\n\s)+" }.join}/
#         puts exp
#       end

#       def parse_sevenbitascii
#         buffer = ""
#         until ["\r", "\n"].include? @input.peek(1)
#           input = @input.get_byte
#           raise TopDown::DoesNotParse if input.each_byte.any? { |b| b > 127 }
#           buffer << input
#         end
#         buffer
#       end

      # The process of moving from this folded multiple-line representation of a property definition to its single line representation is called “unfolding”. Unfolding is accomplished by regarding CRLF immediately followed by a LWSP-char as equivalent to the LWSP-char.
      CRLF_LWSP = /\r?\n[\ |\t]/
      CRLF = /\r?\n/
      ONE_OR_MORE_CRLF = /(\r?\n)+/
      def parse_sevenbitascii
        buffer = ""
        done = false
        until done
          if s = @input.scan(CRLF_LWSP)
            buffer << s[-1] unless @options[:vcard21_line_folding_with_extra_space]
          elsif @input.check(CRLF)
            return to_ascii(buffer)
          else
            buffer << @input.get_byte
          end
        end
        to_ascii buffer
      end

      # everything up to the beginning of CRLF_LWSP or CRLF
      LINE_7BIT = /[^\r\n]*/
      def parse_sevenbitascii
        buffer = ""
        while true
          buffer << @input.scan(LINE_7BIT)
          if s = @input.scan(CRLF_LWSP) # continuation string
            buffer << s[-1] unless @options[:vcard21_line_folding_with_extra_space]
          else # if @input.check(CRLF) # this cannot be false
            return to_ascii(buffer)
          end
        end
        to_ascii buffer
      end


      EQUALS = "="
      def parse_quoted_printable
        buffer = ""
        while true
          input = @input.get_byte
          return buffer if input.empty? # at end of stream
          followed_by_crlf = !@input.match?(CRLF).nil?
          if input == EQUALS and followed_by_crlf
            parse_crlf
          elsif followed_by_crlf
            buffer << input
            return buffer
          else
            buffer << input
          end
        end
      end

      QP_LINE_CONTINUATION = /(.*)=\r?\n$/
      # FIXME: this could be much faster in inline C, since now, we're creating 2 objects per crlf and scanning a line at least twice.
      def parse_quoted_printable
        buffer = ""
        while true
          match = @input.scan_until(CRLF)
          if m = match.match(QP_LINE_CONTINUATION)
            buffer << m[1]
          else
            @input.pos -= 1 # leave the newline to be scanned
            buffer << match.chomp
            return buffer
          end
        end
      end

#       def parse_base64
#         buffer = ""
#         while true
#           input = @input.get_byte
#           buffer << input unless input =~ /[\s]/
#           return buffer if input == "" # at end of stream
#           return buffer if input == "\n" and (@input.peek(2) == "\r\n" or @input.peek(1) == "\n")
#         end
#       end

      # base64    = <MIME RFC 1521 base64 text>
      #   ; the end of the text is marked with two CRLF sequences
      #   ; this results in one blank line before the start of the next property
      # if this vcard has one broken base64 field and a correct one, our nice fallback will fail. but well...
      EMPTY_LINE = /\r?\n\s*\r?\n/
      def parse_base64
        # scan until an empty line occurs
        buffer = @input.scan_until(EMPTY_LINE) or return nil
        @input.pos -= 1
        buffer.gsub!(/\s/, '')
        to_ascii buffer
      end

      def parse_broken_base64
        # scan until an unindented line is encountered
        buffer = @input.scan_until(/\n(?=[^\s])/) or return nil
        @input.pos -= 1
        buffer.gsub!(/\s/, '')
        to_ascii buffer
      end

      def parse_crlf
        @input.scan(CRLF)
      end

#       NON_WORD_CHARD = ["[", "]", "=", ":", ".", ","]
#       NON_XWORD_CHARS = ["[", "]", "=", ":", ".", ",", ";"]
      # word := char [word]
      WORD = /[^\[\]\=\:\.\,]+/
      XWORD = /[^\[\]\=\:\.\,\;]+/   # /[\w-]+/ ???
      X_XWORD = /X-[^\[\]\=\:\.\,\;]+/i
      def parse_xword
        @input.scan(XWORD)
      end

      KNOWNTYPES_LITERALS = Regexp.union(*KNOWNTYPES)
      def parse_knowntype
        value = (@input.scan(KNOWNTYPES_LITERALS) or @input.scan(XWORD)) or return nil
        Param.new("TYPE", value)
      end

      COMMA = /\,/
      # params := 1*(';' [ws] param [ws])
      def parse_params
        params = []
        while p = parse_param
          params << p
          # some programs send us 2.1 cards with params in the 3.0-shorthand version "TYPE=fax,work
          # I added support for that although it is not according to the specs.
          if @input.scan(COMMA)
            val = @input.scan(XWORD) || ""
            params << Param.new(to_ascii(p.key), val)
          end
        end
        params
      end

      SEMICOLON = /\;/
      def parse_param
        # param := ('TYPE' / 'VALUE' / 'ENCODING' / 'CHARSET' / 'LANGUAGE' / 'X-' xword) [ws] '=' [ws] xword / knowntype
        @input.skip(SEMICOLON) or return nil
        @input.skip(OPTIONAL_WS)
        param = (parse_param_key_value or parse_knowntype) or return nil
        @input.skip(OPTIONAL_WS)
        if param.key =~ ENCODING
          @encoding = case param.value
          when BASE64
            :base64
          when QUOTED_PRINTABLE
            :quoted_printable
          end
        end
        param
      end

      EQUALS_REGEXP = /=/
      WS_EQUALS_WS = /[\ |\t]*\=[\ |\t]*/
      def parse_param_key_value
        pos = @input.pos
        key = parse_param_key or return nil
        key.upcase!
        @input.skip(WS_EQUALS_WS) or return rollback(pos)
        value = @input.scan(XWORD) || ""
        Param.new(key, value)
      end

      PARAM_KEY = /(TYPE|VALUE|ENCODING|CHARSET|LANGUAGE)/i
      def parse_param_key
        @input.scan(PARAM_KEY) or @input.scan(X_XWORD)
      end

      OPTIONAL_WSLS = /(\ |\t|\r\n|\n)*/
      OPTIONAL_WS = /[\ |\t]*/

      # produces an array of hashes
      # start := [wsls] vcard [wsls]
      def parse_start
        @input.skip(OPTIONAL_WSLS)
        vcard = parse_vcard or return nil
        @input.skip(OPTIONAL_WSLS)
        vcard
      end

      # 'BEGIN' [ws] ':' [ws] 'VCARD' [ws] 1*CRLF items *CRLF 'END' [ws] ':' [ws] 'VCARD'
      # vcard := beginvcard items *crlf endvcard
      def parse_vcard
        beginvcard = parse_beginvcard or return nil
        items = parse_items or return nil
        @input.skip(ONE_OR_MORE_CRLF) # and ignore it if there are none
        endvcard = parse_endvcard or return nil
        [beginvcard] + items + [endvcard]
      end

      COLON = /:/
      BEGIN_WS_COLON_WS = /BEGIN[:space:]*:[:space:]*/
      VCARD = /VCARD/i
      # 'BEGIN' [ws] ':' [ws] 'VCARD' [ws] 1*crlf
      def parse_beginvcard
        @input.skip(BEGIN_WS_COLON_WS) or return nil
        @input.skip(VCARD) or return nil
        @input.skip(OPTIONAL_WS)
        @input.skip(ONE_OR_MORE_CRLF) or return nil
        { :name => "BEGIN", :value => "VCARD" }
      end

      END_WS_COLON_WS = /END[:space:]*:[:space:]*/
      # 'END' [ws] ':' [ws] 'VCARD'
      def parse_endvcard
        @input.skip(END_WS_COLON_WS) or return nil
        @input.skip(VCARD) or return nil
        { :name => "END", :value => "VCARD" }
      end

      # ( items *crlf item ) / item  <--- left recursion!
      # (item *crlf) items / item  <-- right recursion, better for my parser
      # 1*(item *crlf)  <-- simplification
      def parse_items
        one_star method(:parse_item)
      end

      # item := [groups] name [params] ':' value crlf
      def parse_item
        pos = @input.pos
        groups = parse_groups
        name = parse_name or return rollback(pos)
        @encoding = nil
        params = parse_params
        @input.skip(COLON) or return rollback(pos)
        value = parse_value or return rollback(pos)
        @input.skip(ONE_OR_MORE_CRLF) or return rollback(pos)
        { :groups => groups, :name => name, :params => params, :value => value }
      end

      # groups := groups . word / word
      # group := group*
      def parse_groups
        groups = []
        while x = parse_group
          groups << x
        end
        groups
      end

      DOT = /\./
      # group := word .
      def parse_group
        pos = @input.pos
        word = @input.scan(WORD) and @input.skip(DOT) or return rollback(pos)
        word
      end

      # name := 'LOGO' / 'PHOTO' / 'LABEL' / 'FN' / 'TITLE' / 'SOUND' / 'VERSION' / 'TEL' / 'EMAIL' / 'TZ' / 'GEO' / 'NOTE' / 'URL' / 'BDAY' / 'ROLE' / 'REV' / 'UID' / 'KEY' / 'MAILER' / 'X-' word #; these may be "folded"
      # name := xword # any word except begin or end, those are 'special'
      BEGIN_END = /^(BEGIN|END)$/i
      def parse_name
        word = @input.scan(XWORD) or return nil
        return nil if word =~ BEGIN_END
        word
      end

      # value := sevenbitascii / quotedprintable / base64
      def parse_value
        case @encoding
        when :quoted_printable
          parse_quoted_printable
        when :base64
          parse_base64 or parse_broken_base64
        else
          parse_sevenbitascii
        end
      end
    end

  end
end

