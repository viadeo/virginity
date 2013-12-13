require "#{File.dirname(__FILE__)}/spec_helper"

describe "weird encodings" do
  before do
    @files = Dir.glob("#{VCARDS_ROOT}/encodings/*.vcf")
    @files.should_not be_empty
  end

  specify "should be fixable" do
    @files.each do |file|
      # puts file
      # Vcard.fix_and_clean(File.read(file))
      lambda { Vcard.fix_and_clean(File.read(file)) }.should_not raise_error
    end
  end
end
