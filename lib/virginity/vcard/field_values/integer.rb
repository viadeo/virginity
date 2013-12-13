module Virginity
  module FieldValues

    module Integer
      def integer
        @value.to_i
      end

      def integer=(i)
        @value = @integer.to_s
      end
    end

  end
end
