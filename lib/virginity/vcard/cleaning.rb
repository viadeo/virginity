module Virginity

  module FieldCleaning

    def clean!
      clean_quoted_printable_encoding!
      clean_base64!
      clean_binary_data!
      clean_charsets!
      guess_latin!
      remove_encoding_8bit!
      remove_x_synthesis_ref_params!
      remove_bom!
      clean_types!
      uniq_params!
    end

    # remove QUOTED-PRINTABLE-encoding
    #
    # According to vcard21.doc QUOTED-PRINTABLE cannot occur in structured text and separated text
    # ... but from experience we know it does.
    #
    # Note: reencoding could fail because the characters are not encodable as text
    LIST_NAMES = %w(CATEGORIES)
    QUOTED_PRINTABLE = /^quoted-printable$/i
    ENCODING = /^ENCODING$/i
    def clean_quoted_printable_encoding!
      return unless @params.any? {|p| p.key =~ ENCODING and p.value =~ QUOTED_PRINTABLE }
      if @value.include?(";") # if the unencoded value contains ";" it's a list (or a structured value)
        v = @value.split(";").map { |e| EncodingDecoding::decode_quoted_printable(e) }
        @value = EncodingDecoding::encode_text_list(v, ";")
      elsif LIST_NAMES.include?(@name) or @value.include?(",") # kludge
        v = @value.split(",").map { |e| EncodingDecoding::decode_quoted_printable(e) }
        @value = EncodingDecoding::encode_text_list(v, ",")
      else
        v = EncodingDecoding::decode_quoted_printable(@value)
        @value = EncodingDecoding::encode_text(v)
      end
      @params.delete_if {|p| p.key =~ ENCODING and p.value =~ QUOTED_PRINTABLE }
      self
    end

    # convert BASE64 to b
    def clean_base64!
      @params.each do |param|
        next unless param.key =~ ENCODING and param.value =~ /^base64$/i
        param.value = "b"
      end
      self
    end

    def clean_binary_data!
      return unless @params.any? {|param| param.key =~ ENCODING and param.value =~ /^b$/i }
      @value.gsub!(/\s/, '')
      self
    end

    def remove_encoding_8bit! # since it's already implicitly encoded in 8 bits...
      @params.delete_if {|param| param.key =~ ENCODING and param.value =~ /^8BIT$/ }
      self
    end

    CHARSET = "CHARSET"
    def clean_charsets!
      return unless charset = @params.find { |param| param.key.casecmp(CHARSET) == 0 }
      @value.encode!(Encoding::UTF_8, charset.value) unless charset.value == "UTF-8"
      @value = @value.force_encoding(Encoding::UTF_8)
      @params.delete charset
      self
    end

    # Why do we have two boms? well duh, the string could be in either of those encodings!
    BOM_UTF8 = [65279].pack('U')
    BOM_BINARY = BOM_UTF8.dup.force_encoding(Encoding::BINARY)
    def remove_bom!
      if @value.encoding == Encoding::BINARY
        @value.gsub!(BOM_BINARY, '')
      else
        # if it's not utf-8, it's callers fault.
        @value.gsub!(BOM_UTF8, '') # remove the BOM
      end
      self
    end

    CASE_SENSITIVE_TYPES = /^(DOM|INTL|POSTAL|PARCEL|HOME|WORK|OTHER|PREF|VOICE|FAX|MSG|CELL|PAGER|BBS|MODEM|CAR|ISDN|VIDEO|AOL|APPLELINK|ATTMAIL|CIS|EWORLD|INTERNET|IBMMAIL|MCIMAIL|POWERSHARE|PRODIGY|TLX|X400|GIF|CGM|WMF|BMP|MET|PMB|DIB|PICT|TIFF|PDF|PS|JPEG|QTIME|MPEG|MPEG2|AVI|WAVE|AIFF|PCM|X509|PGP)$/i
    TYPE = "TYPE"
    def clean_types!
      params(TYPE).each do |type|
        type.value.upcase! if type.value =~ CASE_SENSITIVE_TYPES
      end
      self
    end

    X_SYNTHESIS_REF = /^X-Synthesis-Ref\d*$/i
    def remove_x_synthesis_ref_params!
      @params.delete_if {|p| p.key =~ X_SYNTHESIS_REF or p.value =~ X_SYNTHESIS_REF }
      self
    end

    def uniq_params!
      params.uniq!
      self
    end

    def guess_latin!
      return if @value.valid_encoding?
      @value.encode!(Encoding::UTF_8, "ISO-8859-1")
    end
  end


  module VcardCleaning

    # run almost every clean method on whole vcards and on separate fields (FieldCleaning), in a correct order
    def clean!
      clean_version!
      remove_x_abuids!
      remove_x_irmc_luids!
      rstrip_text_fields!
#       strip_structured_fields! # mh, better not do this here. It's too much
      remove_empty_fields!
      fields.each { |field| field.clean! }
      clean_categories!
      unpack_nicknames!
      clean_orgs!
      max_one_name!
      clean_name!
      clean_dates!
      clean_adrs!
      convert_xabadrs_to_param!
      convert_xablabels_to_param!
      remove_duplicate_lines!
      remove_singleton_groups!
      clean_same_value_fields!
      remove_subset_addresses!
      reset_empty_formatted_name!
      self
    end
    alias_method :super_clean!, :clean!

    # make sure there is exactly one version-field that says "3.0"
    # and do that in a smart way so the vcard is not changed if it's not nescessary
    VERSION30 = "VERSION:3.0"
    VERSION = "VERSION"
    def clean_version!
      unless (self/VERSION30).size == 1
        lines_with_name(VERSION).each {|f| delete_field(f) }
        self << VERSION30
      end
      self
    end

    X_ABUID = "X-ABUID"
    # OS-X is not sending those anymore, but existing contact can still contain those fields
    def remove_x_abuids!
      lines_with_name(X_ABUID).each {|f| delete_field(f) }
      self
    end

    # Sony-Ericsson phones send those. They don't mean anything for us. They are meant for Windows software that syncs the desktop with a phone afaik.
    X_IRMC_LUID = "X-IRMC-LUID"
    def remove_x_irmc_luids!
      lines_with_name(X_IRMC_LUID).each {|f| delete_field(f) }
      self
    end

    # why? to remove trailing semicolons like in: "ORG:foo;bar;"
    def clean_orgs!
      organizations.each { |org| org.reencode!(:variable_number_of_fields => true) }
      self
    end

    # since we could have received a vcard with too many semicolons
    NAME = 'N'
    def max_one_name!
      n_fields = lines_with_name(NAME)
      return self unless n_fields.size > 1
      # remove all N fields except the biggest
      n_fields.delete(n_fields.max_by { |f| f.raw_value.size })
      delete(*n_fields)
      self
    end

    def clean_name!
      lines_with_name(NAME).each { |n| n.reencode! }
      self
    end

    # there's no use in keeping fields without a value
    def remove_empty_fields!
      lines.delete_if do |x|
        x.raw_value.strip.empty? or (x.respond_to? :values and x.values.join.empty?)
      end
      self
    end

    # make one field containing all of values of fields with the same name
    def clean_multivalue_fields!(name)
      fields = lines_with_name(name)
      while fields.size > 1
        last = fields.pop
        fields.first.values.concat( last.values.to_a )
        delete_field(last)
      end
      self
    end

    # concatenate all CATEGORIES-lines, make categories unique and sorted
    CATEGORIES = "CATEGORIES"
    def clean_categories!
      clean_multivalue_fields!(CATEGORIES) # concat
      if categories = lines_with_name(CATEGORIES).first
        categories.values = categories.values.map { |c| c.strip }.sort.uniq
      end
      self
    end

    # after unpacking there SHOULD be one field for each value
    # the order MUST NOT change.
    def unpack_field!(field)
      return if field.values.size == 1
      field.unpacked.each {|f| add_field(f) }
      delete_field(field)
    end

    def unpack_list!(list_name)
      lines_with_name(list_name).each { |field| unpack_field!(field) }
      remove_empty_fields!
      self
    end

    # after unpacking there should be one categories lines per category
    # the order should not change, but that doesn't actually matter for categories
    def unpack_categories!
      unpack_list!(CATEGORIES)
    end

    # after unpacking there should be one nickname value per NICKNAME
    # the order should not change.
    NICKNAME = "NICKNAME"
    def unpack_nicknames!
      unpack_list!(NICKNAME)
    end

    # if there's only one field in a certain group that group can be reset
    def remove_singleton_groups!
      groups = fields.map {|f| f.group }.compact!
      fields.each do |field|
        next if field.group.nil?
        field.group = nil if groups.select { |g| g == field.group }.size == 1
      end
      self
    end

    def convert_custom_osx_field_to_param!(fields)
      fields.each do |custom|
        unless custom.group.nil?
          same_group = where(:group => custom.group) - [custom]
          same_group.each { |field| field.params << custom.to_param }
        end
        delete_field(custom)
      end
      self
    end

    def convert_xabadrs_to_param!
      convert_custom_osx_field_to_param! lines_with_name("X-ABADR")
    end

    def convert_xablabels_to_param!
      convert_custom_osx_field_to_param! lines_with_name("X-ABLabel")
    end

    def remove_duplicate_lines!
      fields.uniq!
      self
    end

    # merge fields with the same value (collect all params in the remaining field)
    def clean_same_value_fields!
      fields.each do |upper|
        next if Vcard::SINGLETON_FIELDS.include?(upper.name)
        fields.each do |lower|
          next if lower.object_id == upper.object_id # nescessary
          next unless lower.name == upper.name # optimisation
          next unless lower.raw_value == upper.raw_value # optimisation
          begin
#             puts "merging #{upper} and #{lower}"
            upper.merge_with!(lower)
            delete_field(lower)
#             puts "merged: #{upper}"
          rescue # nescessary
          end
        end
      end
      self
    end

    # removes fields that are a subset of another existing field
    #
    # In the following example, field two is a subset of field one.
    #   one = Field.new("ADR;TYPE=HOME:;;Bickerson Street 4;Dudley Town;;6215 AX;NeverNeverland")
    #   two = Field.new("ADR;TYPE=HOME:;;Bickerson Street 4;Dudley Town;;;")
    #   two.subset_of?(one) ==> true
    def remove_subsets_of_structured_fields!(fields)
      fields = fields.dup
      while field = fields.pop
        delete_field(field) if fields.any? {|other| field.subset_of?(other) }
      end
      self
    end

    def remove_subset_addresses!
      remove_subsets_of_structured_fields!(addresses)
    end

    def reset_empty_formatted_name!
      name.reset_formatted!
      self
    end

    def remove_extra_photos!(p = photos)
      p.shift
      p.each { |line| delete_field(line) }
      self
    end

    def remove_extra_logos!
      remove_extra_photos!(logos)
    end

    RSTRIPPABLE_FIELDS = /^(EMAIL|FN|IMPP|NOTE|TEL|URL)$/i
    # remove right hand whitespace from the values of all RSTRIPPABLE_FIELDS
    def rstrip_text_fields!
      fields.each do |field|
        field.raw_value.rstrip! if field.name =~ RSTRIPPABLE_FIELDS
      end
      self
    end

    # remove whitespace around parts of a name
    def strip_structured_fields!
      (lines_with_name(NAME) + organizations + addresses).each do |field|
        field.components.each { |component| field.send(component.to_s+'=', field.send(component).strip) }
      end
    end

    def clean_dates!
      (birthdays + anniversaries + dates).each do |day|
        begin
          day.date = day.date.to_s # normalize the date format
        rescue => e
          nil
        end
      end
    end

    def clean_adrs!
      lines_with_name("ADR").each do |adr|
        adr.reencode! if EncodingDecoding::decode_text_list(adr.raw_value, ";").size != 7
      end
    end
  end
end
