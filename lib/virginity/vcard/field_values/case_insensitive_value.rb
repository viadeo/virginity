module Virginity
  module FieldValues

    module CaseInsensitiveValue
      def ==(other)
        group == other.group &&
          has_name?(other.name) &&
          params == other.params &&
          (raw_value.casecmp(other.raw_value) == 0)
      end
    end
  end
end
