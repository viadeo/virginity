require "#{File.dirname(__FILE__)}/spec_helper"

describe "weird encodings" do
  # FIXME: The whole point of this was to show that real life data could be parsed.
  # I should make a decision to either remove the test or find a way to make vcards with different sorts of charsets.

  before do
    pending "The vcf-files used in these tests have been censored."
    @files = Dir.glob("#{VCARDS_ROOT}/encodings/*.vcf")
    @files.should_not be_empty
  end

  specify "should be fixable" do
    pending "The vcf-files used in these tests have been censored."
    @files.each do |file|
      lambda { Vcard.fix_and_clean(File.read(file)) }.should_not raise_error
    end
  end
end
