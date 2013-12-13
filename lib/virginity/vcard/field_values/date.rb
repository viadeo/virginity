require 'date'

module Virginity
  module FieldValues

    module DateValue
      def date
        Date.parse(text)
      end

      def date=(d)
        self.text = d.to_s
      end
    end
  end
end
