require "#{File.dirname(__FILE__)}/spec_helper"

describe "Query" do
  before do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
    @jason = DirectoryInformation.new(@jason_vcf)
  end

  specify "should return an array of contentlines" do
    (@jason/"N").size.should == 1
    (@jason/"N").first.should be_instance_of ContentLine
  end

  specify "should work with name-queries" do
    (@jason/"N").size.should == 1
    (@jason/"N").first.raw_value.should include("Jason")
    (@jason/"PHOTO").size.should == 1
  end

  specify "querying by group" do
    (@jason/"x.N").size.should == 0
  end

  specify "querying by value" do
    (@jason/":Jason").size.should == 2 # the FN and NAME
    (@jason/":Jason").first.name.should == "FN"
    (@jason/":Jason").last.name.should == "NAME" # NAME is NOT a standard field!
    (@jason/":support@soocial.com").should == @jason/"EMAIL"
  end

  specify "querying by combinations" do
    (@jason/"FN:Jason").size.should == 1
    (@jason/"FN:Josan").size.should == 0
  end

  specify "querying first match by combinations" do
    @jason.first_match("FN:Jason").should_not be_instance_of Array
    @jason.first_match("FN:Jason").should_not be_nil
  end

  specify "querying by params" do
    @jason.query("EMAIL").should_not be_empty
    @jason.query(";TYPE=WORK").should_not be_empty
    @jason.query("EMAIL").should == @jason.query(";TYPE=WORK")
  end

end


describe "Query" do
  before do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
    @jason = Vcard.from_vcard(@jason_vcf)
  end

  specify "querying by sha1-hash" do
    sha1 = @jason.where(:name => "PHOTO").first.sha1
    sha1.should_not be_empty
    @jason.where(:sha1 => sha1).should == @jason.where(:name => "PHOTO")
  end

  specify "querying by TYPE" do
    work = @jason.where(:has_type => "WORK")
    work.size.should == 1
    work.first.name.should == "EMAIL"
  end

  specify "querying by PARAM" do
    work = @jason.where(:has_param => ["TYPE", "WORK"])
    work.size.should == 1
    work.first.name.should == "EMAIL"

    encoding = @jason.where(:has_param => ["ENCODING", "b"])
    encoding.size.should == 1
    encoding.first.name.should == "PHOTO"
  end

  specify "querying by PARAM-key" do
    type = @jason.where(:has_param_with_key => "TYPE")
    type.map { |x| x.name }.sort.should == %w(EMAIL PHOTO)

    encoding = @jason.where(:has_param_with_key => "ENCODING")
    encoding.map(&:name).should == %w(PHOTO)
  end

  specify "querying by PARAM-key and name" do
    type = @jason.where(name: 'EMAIL', :has_param_with_key => "TYPE")
    type.map { |x| x.name }.should == %w(EMAIL)
  end
end
