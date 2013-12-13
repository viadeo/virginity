module Virginity
  module FieldValues

    class StructuredText
      def self.define(components)
        m = Module.new
        m.const_set("COMPONENTS", components)
        m.module_eval <<-RUBY
          def components
            COMPONENTS
          end

          def values
            EncodingDecoding::decode_structured_text(@value, COMPONENTS.size)
          end

          def empty?
            values.all? {|v| v.empty? }
          end

          def reencode!(options={})
            v = values
            unless options[:variable_number_of_fields]
              v.pop while v.size > components.size
              v.push(nil) while v.size < components.size
            else
              v.pop while v.last.empty?
            end
            @value = EncodingDecoding::encode_structured_text(v)
          end

          def [](component)
            raise "which component? \#\{component\}?? I only know \#\{components.inspect\}" unless components.include? component.to_sym
            send("\#\{component\}".to_sym)
          end

          def []=(component, new_value)
            raise "which component? \#\{component\}?? I only know \#\{components.inspect\}" unless components.include? component.to_sym
            send("\#\{component\}=", new_value)
          end
        RUBY

        components.each_with_index do |component, idx|
          m.module_eval <<-RUBY
            def #{component}
              values[#{idx}]
            end

            def #{component}=(new_value)
              structure = values
              structure[#{idx}] = new_value.to_s
              @value = EncodingDecoding::encode_structured_text(structure)
            end

            def subset_of?(other_field)
              components.all? do |component|
                send(component).empty? or send(component) == other_field.send(component)
              end
            end

            def superset_of?(other_field)
              other_field.subset_of?(self)
            end
          RUBY
        end
        m
      end
    end

  end
end
