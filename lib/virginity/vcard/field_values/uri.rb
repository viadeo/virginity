module Virginity
  module FieldValues

    # needs module Text
    module Uri
      def uri
        URI::parse(text)
      end

      def uri=(new_uri)
        self.text = new_uri.to_s
      end
    end
  end
end
