module FieldsRegistry
  def be_registered_for(field)
    FieldRegistryMatcher.new(field, described_class)
  end

  class FieldRegistryMatcher
    include RSpec::Matchers::Pretty

    def initialize(*args)
      @field, @klass = args
      super()
    end

    def matches?(actual)
      Virginity::Field[@field].should == @klass
    end
  end

  RSpec.configure do |config|
    config.include self
  end
end
