require 'virginity'
require 'digest/sha1'


# FIXME move this to the API
module Virginity
  class ContentLine

    # api_id, a SHA1 hash of the whole line
    def api_id
      Digest::SHA1.hexdigest(to_s)
    end
  end
end


require 'virginity/api_extensions/fields_to_xml'


module Virginity
  class Param
    def as_json(options = {})
      { key => value }
    end
  end

  module StructuredTextAsJson
    def as_json(options = {})
      hash = {}
      components.each do |c|
        hash[c.to_s] = send(c)
      end
      field_as_json(hash, options)
    end
  end

  module SeparatedTextAsJson
    def as_json(options = {})
      field_as_json({ :values => [values] }, options)
    end
  end

  module Values
    module Binary
      def as_json(options = {})
        field_as_json({ :binary => binary }, options)
      end
    end
  end

  class BaseField < ContentLine
    def group_and_params_as_json(options = {})
      { :group => group, :params => params }
    end

    def field_as_json(hash, options = {})
      group_and_params_as_json(options).merge(hash).delete_if { |k,v| v.nil? }
    end
  end



  class Email < BaseField
    def as_json(options = {})
      field_as_json({ :address => address }, options)
    end
  end

  class Tel < BaseField
    def as_json(options = {})
      field_as_json({ :number => number }, options)
    end
  end

  class Adr < BaseField
    include StructuredTextAsJson
  end

  class Name < BaseField
    include StructuredTextAsJson
  end

  class Separated < BaseField
    include SeparatedTextAsJson
  end

end
