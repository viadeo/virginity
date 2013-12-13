module Virginity

  class XSoocialCustom < BaseField
    PARTS = %w(key_name value)
    include FieldValues::StructuredText.define(PARTS)
    register_for "X-SOOCIAL-CUSTOM"

    def value
      rewrite_old_kv!
      super
    end

    def key_name
      rewrite_old_kv!
      super
    end

    def text
      value
    end

    def text=(txt)
      self.value = txt
    end

    def to_s
      rewrite_old_kv!
      super
    end

    def rewrite_old_kv!
      if name = params('NAME')[0]
        self.key_name, self.value = name.value, EncodingDecoding.decode_text(raw_value)
        params.delete_if { |p| p.key == "NAME" }
      end
    end
  end


  class XSoocialRemovedCategory < BaseField
    include FieldValues::Text
    register_for "X-SOOCIAL-REMOVED-CATEGORY"
  end

end
