module FieldsParsingMatchers
  def self.included(mod)
    mod.extend(ClassMethods)
  end

  module ClassMethods
    def when_parsing(string, &block)
      describe "when parsing #{string}" do
        subject { Virginity::Field.from_line string }
        instance_eval(&block)
      end
    end
  end

  RSpec.configure do |config|
    config.include self
  end
end
