module Virginity
  module Fixes
    def unfold_faulty_qp_lines(faulty_lines)
      lines = faulty_lines.dup
      loop do # unfold line that do not begin with " " but are encoded as QP
        changed = false
        lines.each_with_index do |line, i|
          # if line is QP, ends with equals and is not the last line
          if line =~ /ENCODING=QUOTED-PRINTABLE/i and line =~ /=$/ and lines.length > i+1
            lines[i] = lines[i].chomp('=') # remove the soft-line break, the last character, (=)...
            lines[i] += lines.delete_at(i+1) # ...and add the next line to the failing line.
            changed = true
          end
        end
        break unless changed
      end
      lines
    end

    def non_empty_lines(faulty_lines) # (needed for simon3.vcf)
      faulty_lines.reject {|line| line.empty? }
    end

    # for osx
    # more info on this Base64-line: http://www.imc.org/imc-vcard/mail-archive/msg00555.html
    def remove_spaces_from_base64_lines(faulty_lines)
      faulty_lines.map do |line|
        if line =~ /BASE64/ # FIXME, this will break if the value contains this string. --> so let's do this in the field-class?
          line.gsub(/\s/, "")
        else
          line
        end
      end
    end

    def self.line_parts(line)
      ContentLine::line_parts(line)
    rescue InvalidEncoding
      # so, it's invalid 3.0 encoded, could it be a 2.1-encoding?
      DirectoryInformation::line21_parts(line)
    end

    # FIXME --> width can't be greater than width in the normal folding method... but it is now :-(
    def self.photo_folding_like_apple(value, options = {})
      width = options[:width] || 78
      line_ending = (options[:windows_line_endings] ? "\r\n" : "\n")
      s = line_ending + "  " + value.gsub(/.{#{width-2},#{width-2}}/) {|x| x + line_ending + "  "}
      s.sub(/#{line_ending}  $/,"") # remove the last line ending if if it so happens to be that the last line is 'empty'
    end

    def self.sane_line_endings(s)
      s.gsub(LineFolding::LINE_ENDING, "\n")
    end

    def self.should_be_folded?(line)
      return false if line =~ /\A $/ # TODO: clarify this, it was line.first, which takes the first string.
      if line.include?(":") # probably a field
        unless line[0] == ":" or line.split(":").first.match(/[\(\)]/)
          # it is a name then, so it's a new field
          return false
        end
      end
      true
    end

    def self.unfold_wrongly_folded_lines(s)
      x = ""
      sane_line_endings(s).split("\n").each do |line|
        if should_be_folded?(line.dup)
          x << " " + line
        else
          x << line
        end
        x << "\n"
      end
      x
    end

    def self.remove_ascii_ctl_chars(s)
      ctl = (0..31).to_a + [127]
      v = ""
      s.each_byte do |c|
        v << c unless ctl.include? c
      end
      v
    end

    def self.reencode_qp(qp, type=:value)
      decoded = EncodingDecoding::decode_quoted_printable(qp)
      case type
      when nil
        @value = EncodingDecoding::encode_text decoded
      when :separated
        @value = EncodingDecoding::encode_text_list [decoded]
      when :structured
        @value = EncodingDecoding::encode_structured_text [decoded]
      else
        raise TypeError, type
      end
    end

    EQUALS_SIGN_WITHOUT_HEX = /=(([^0-9^A-F])|(.[^0-9^A-F]))/

    def self.fix_faulty_qp_chars(s)
      x = Virginity::LineFolding::unfold_and_split(s)
      y = x.map do |l|
        if l =~ /QUOTED\-PRINTABLE/
          l =~ /(.*):(.*)/
          prevalue, value = $1, $2
          value = value.gsub(EQUALS_SIGN_WITHOUT_HEX) { |s| " #{$1}" }
          "#{prevalue}:#{value}"
        else
          l
        end
      end
      y.join("\n")
    end

    def self.guess_latin1(s)
      x = Vcard.new(s).super_clean!
      x.fields.each do |f|
        begin
          f.to_s.encode('UTF-8//TRANSLIT', Encoding::UTF_8)
          f.to_s.force_encoding(LATIN1).encode
        rescue EncodingError
          print "\tguessing Latin1 for #{f.to_s.inspect}"
          f.params << Param.new("CHARSET", "Latin1")
          f.clean_charsets!
          raise "GAAAAAAAAH!" unless f.to_s.is_utf8?
          puts "\t-->\t" + f.to_s.inspect
        end
      end
      x.super_clean!.to_s
    end

#     def faulty?(lns=lines)
#       lns.any? { |line| not line =~ %r{#{Bnf::LINE}}i }
#     end

#     def fix!(lines)
#       ls = lines.dup
#       ls = unfold_faulty_qp_lines(ls)
#       ls = non_empty_lines(ls)
#       raise InvalidEncoding.new("I do not know how to repair this vcard:\n" + inspect) if faulty?(ls)
#       ls
#     end

#     def fixed!
#       original = lines.join("\n")
#       ls = lines.dup
#       before = original.dup
#       after = ""
#       while before != after and faulty_lines?(lines)
#         before = ls.join("\n")
#         ls = unfold_faulty_qp_lines(ls)
#         ls = non_empty_lines(ls)
#         after = ls.join("\n")
#       end
#       raise InvalidEncoding.new("I do not know how to repair this vcard:\n" + original) if faulty_lines?(lines)
#       lines
#     end

  end
end


class Virginity::Vcard < Virginity::DirectoryInformation

  def self.fields_from_broken_vcard(vcard_as_string)
    lines = Virginity::LineFolding::unfold_and_split(vcard_as_string.lstrip).map do |line|
      begin
        # if it is not valid 3.0, could it be a 2.1-line?
        Virginity::Field.parse(line)
      rescue
        group, name, params, value = DirectoryInformation::line21_parts(line)
        Virginity::Field[name].new(name, value, params, group, :no_deep_copy => true)
      end
    end
  end

  def self.valid_utf8?(v)
    if v.to_s.dup.force_encoding(Encoding::UTF_8).valid_encoding?
      true
    else
      false
    end
  rescue EncodingError
    return false
  end

  # NB. this only works for vCard 3.0, not for 2.1!
  def self.fix_and_clean(vcard_as_string)
    fixes ||= []
    # puts vcard_as_string
    # puts "fixes => #{fixes.inspect}"
    lines = fields_from_broken_vcard(vcard_as_string)
    v = Virginity::Vcard.new(lines)
    v.super_clean!
    valid_utf8?(v)
    v
  rescue EncodingError
    #puts e.class, e
    if !fixes.include?(:faulty_qp)
      newcard = Fixes::fix_faulty_qp_chars(vcard_as_string)
      fixes << :faulty_qp
    elsif !fixes.include?(:guess_latin1)
      newcard = Fixes::guess_latin1(lines)
      fixes << :guess_latin1
    else
      File.open("illegal_sequence_#{vcard_as_string.hash}.vcf", "wb") do |f|
        f.puts Virginity::Vcard.new(vcard_as_string).super_clean!
      end
      raise
    end
    vcard_as_string = newcard
    retry
  rescue Virginity::InvalidEncoding, Virginity::Vcard21::ParseError => e
    if !fixes.include?(:fix_folding)
      vcard_as_string = Fixes::unfold_wrongly_folded_lines(vcard_as_string)
      fixes << :fix_folding
      retry
    elsif !fixes.include?(:weird_mac_16bit_encoding_that_is_not_utf16) && vcard_as_string.include?("\000")
      vcard_as_string.gsub!("\000", "")
      fixes << :weird_mac_16bit_encoding_that_is_not_utf16
      retry
    else
      raise
    end
  end
end
