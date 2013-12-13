module Virginity
  module FieldValues

    class OptionalStructuredText < StructuredText
      def self.define(components)
        m = super

        m.module_eval <<-RUBY, __FILE__, __LINE__+1
          def reencode!(options = {})
            v = values

            v.pop while v.last.empty?

            @value = EncodingDecoding::encode_structured_text(v)
          end
        RUBY

        components.each_with_index do |component, idx|
          m.module_eval <<-RUBY, __FILE__, __LINE__+1
            def #{component}=(new_value)
              structure = values
              structure[#{idx}] = new_value.to_s

              structure.pop while structure.size > 0 && (structure.last.nil? || structure.last.empty?)

              @value = EncodingDecoding::encode_structured_text(structure)
            end
          RUBY
        end

        m
      end
    end
  end
end
