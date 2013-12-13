module Virginity
  module FieldValues

    module Boolean
      def boolean
        (@value.downcase == "true")
      end

      def boolean=(b)
        @value = b ? "true" : "false"
      end
    end
  end
end
