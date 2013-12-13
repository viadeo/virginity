require 'digest'
require 'virginity/encodings'
require 'virginity/dir_info'
require 'virginity/vcard/cleaning'
require 'virginity/vcard/categories'
require 'virginity/vcard/name_handler'
require 'virginity/vcard/fields'
require 'virginity/vcard/fields_osx'
require 'virginity/vcard/fields_soocial'
require 'virginity/vcard/patching'

module Virginity

  class InvalidVcard < Error
    attr_reader :original

    def initialize(msg, original = $!)
      super(msg)
      @original = original
    end
  end

  # rfc 2426, vCard MIME Directory Profile
  class Vcard < DirectoryInformation
    include VcardCleaning
    include VcardCategories
    include Patching
    include Encodings

    def self.diff(old, new)
      Patching::diff(old, new)
    end

    EMPTY = "BEGIN:VCARD\nN:;;;;\nVERSION:3.0\nEND:VCARD\n"

    VCARD_REGEX = /^[\ \t]*VCARD[\ \t]*$/i
    def initialize(lines = EMPTY, options = {})
      if lines.is_a? Array
        @lines = lines.map {|line| line.to_field }
      else # it's expected to be a String
        verify_utf8ness lines
        @lines = LineFolding::unfold_and_split(lines.lstrip).map { |line| Field.parse(line) }
      end
      raise InvalidVcard, "missing BEGIN:VCARD" unless @lines.first.name =~ Field::BEGIN_REGEX
      raise InvalidVcard, "missing END:VCARD" unless @lines.last.name =~ Field::END_REGEX
      raise InvalidVcard, "missing BEGIN:VCARD" unless @lines.first.raw_value =~ VCARD_REGEX
      raise InvalidVcard, "missing END:VCARD" unless @lines.last.raw_value =~ VCARD_REGEX
    rescue => error
      raise InvalidVcard, error.message
    end

    # the empty vcard
    def self.empty
      new(LineFolding::unfold_and_split(EMPTY.lstrip).map { |line| Field.parse(line) })
    end

    # import vcard21 and convert it to 3.0
    def self.from_vcard21(vcf, options = {})
      verify_utf8ness vcf
      vcard = new(lines_from_vcard21(vcf, options), options)
      vcard.clean_version!
    rescue => error
      raise InvalidVcard, error.message
    end

    VERSION21 = /^VERSION\:2\.1(\s*)$/i
    def self.parse(vcf, options = {})
      vcf = vcf.to_s
      verify_utf8ness vcf
      if vcf =~ VERSION21
        from_vcard21(vcf, options)
      else
        new(vcf, options)
      end
    end

    def self.from_vcard(vcf, options = {})
      parse(vcf, options)
    end

    def self.load_all_from(filename, options = {})
      list(File.read(filename), options)
    end

    END_VCARD = /^END\:VCARD\s*$/i
    # split a given string of concatenated vcards to an array containing one vcard per element
    def self.vcards_in_list(vcf)
      s = StringScanner.new(vcf)
      array = []
      while !s.eos?
        if v = s.scan_until(END_VCARD)
          v.lstrip!
          array << v
        else
          puts s.peek(100)
          break
        end
      end
      array
    end

    # returns an array of Vcards for a string of concatenated vcards
    def self.list(vcf, options = {})
      vcards_in_list(vcf).map do |v|
        from_vcard(v, options)
      end
    end

    def inspect
      super.chomp(">") + " name=" + name.to_s.inspect + ">"
    end

    def dir_info
      DirectoryInformation.new(to_s)
    end

    def deep_copy
      Marshal::load(Marshal::dump(self))
    end

    alias_method :fields, :lines
    alias_method :delete_field, :delete_content_line

    # add a field and return it
    # if a block is given, then the new field is yielded so it can be changed
    def add_field(line)
      end_vcard = @lines.pop
      raise InvalidVcard, "there is no last line? ('END:VCARD')" if end_vcard.nil?
      @lines << (field = Field.parse(line))
      @lines << end_vcard
      yield field if block_given?
      field
    end

    # add a field, returns the vcard
    def <<(line)
      add_field(line)
      self
    end
    alias_method :push, :<<

    # a vCard 2.1 string representation of this vCard
    # if :windows_line_endings => true then lines end with \r\n otherwise with \n
    CRLF = "\r\n"
    def to_vcard21(options = {})
      line_ending = options[:windows_line_endings] ? CRLF : LF
      fields.map { |field| field.encode21(options) }.join(line_ending)
    end

    # are all fields also present or supersets in other?
    IGNORE_IN_SUBSET_COMPARISON = %w(BEGIN END FN)
    def subset_of?(other)
      fields.all? do |field|
        if IGNORE_IN_SUBSET_COMPARISON.include?(field.name)
          true
        else
          # puts "-----\n"
          # puts "#{field} in #{other}?\n"
          other.lines_with_name(field.name).any? do |f|
            begin
              # puts "considering #{f} ==> #{f.raw_value == field.raw_value or field.subset_of?(f)}"
              f.raw_value == field.raw_value or field.subset_of?(f)
            rescue NoMethodError
              false
            end
          end
        end
      end
    end

    SINGLETON_FIELDS = %w(N FN BEGIN END VERSION)
    # import all fields except N, FN, and VERSION from other (another Vcard)
    # duplicate fields are deduped
    def assimilate_fields_from!(other)
      other.fields.each do |field|
        next if SINGLETON_FIELDS.include? field.name.upcase
        push(field)
      end
      clean_same_value_fields!
      self
    end

    def add(name)
      add_field(name + ":") do |field|
        yield field if block_given?
      end
    end

    def add_email(address = nil)
      add(EMAIL) do |email|
        email.address = address.to_s
        yield email if block_given?
      end
    end

    def add_telephone(number = nil)
      add(TEL) do |tel|
        tel.number = number.to_s
        yield tel if block_given?
      end
    end

    def name
      @name ||= NameHandler.new(self)
    end

    ADR = "ADR"
    BDAY = "BDAY"
    CATEGORIES = "CATEGORIES"
    EMAIL = "EMAIL"
    IMPP = "IMPP"
    LOGO = "LOGO"
    NICKNAME = "NICKNAME"
    TEL = "TEL"
    NOTE = "NOTE"
    ORG = "ORG"
    PHOTO = "PHOTO"
    TITLE = "TITLE"
    URL = "URL"
    def addresses; lines_with_name(ADR); end
    def birthdays; lines_with_name(BDAY); end
    def categories; lines_with_name(CATEGORIES); end
    def emails; lines_with_name(EMAIL); end
    def impps; lines_with_name(IMPP); end
    def logos; lines_with_name(LOGO); end
    def nicknames; lines_with_name(NICKNAME); end
    def telephones; lines_with_name(TEL); end
    def notes; lines_with_name(NOTE); end
    def organizations; lines_with_name(ORG); end
    alias_method :organisations, :organizations # Britania rules the waves!
    def photos; lines_with_name(PHOTO); end
    def titles; lines_with_name(TITLE); end
    def urls; lines_with_name(URL); end
    def custom_im_fields; @lines.select{|line| line.is_a? Virginity::Vcard::CustomImField}; end

    XABRELATEDNAMES = "X-ABRELATEDNAMES"
    def related_names; lines_with_name(XABRELATEDNAMES); end
    XABDATE = "X-ABDATE"
    def dates; lines_with_name(XABDATE); end
    XANNIVERSARY = "X-ANNIVERSARY"
    def anniversaries; lines_with_name(XANNIVERSARY); end
  end

end
