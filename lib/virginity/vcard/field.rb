require 'virginity/vcard/base_field'

module Virginity

  # Basic field, if we don't know anything about it, we assume it can at least handle text encoding
  class Field < BaseField
    include FieldValues::Text

    field_register.default = self
  end


  # monkey patch ContentLine to make a #to_field method
  class ContentLine
    # convert to a vcard-field (see Field)
    def to_field
      Field.parse(self)
    end
  end


end
