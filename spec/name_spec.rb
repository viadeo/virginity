require "#{File.dirname(__FILE__)}/spec_helper"


describe "Name handling" do
  before do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
    @jason = Virginity::Vcard.new(@jason_vcf)
  end

  specify "reading name" do
    @jason.name.given.should == "Jason"
    @jason.name.family.should == "de Aap"
    @jason.name.to_s.should == "Jason"
  end

  specify "changing the name" do
    @jason.name.reset_formatted!
    @jason.name.given.should == "Jason"
    @jason.name.family.should == "de Aap"
    @jason.name.to_s.should == "Jason de Aap"
    @jason.name.family = "el Monkey"
    @jason.name.to_s.should == "Jason el Monkey"
    @jason.name.complete.should == "Jason el Monkey"
    @jason.name.suffix = "Bsc."
    @jason.name.complete.should == "Jason el Monkey Bsc."
  end

end


describe Vcard::NameHandler do
  specify "a new name" do
    name = Vcard::NameHandler.new(Vcard.new.to_s)
    name.family.should == ""
    name.nicknames.should be_empty
    name.add_nickname "jaap"
    name.nicknames.should_not be_empty
    name.has_nickname?("jaap").should be_true
    name.remove_nickname "jaap"
    name.nicknames.should be_empty
  end

  specify "merging names" do
    a = Vcard::NameHandler.new(Vcard.new)
    b = Vcard::NameHandler.new(Vcard.new)
    a.given = "Jaap"
    b.given = "Jaap"
    lambda { a.merge_with! b }.should_not raise_error
    b.family = "Paaj"
    lambda { a.merge_with! b }.should_not raise_error
    a.family.should == "Paaj"
    a.family = "PAAJ"
    lambda { a.merge_with! b }.should raise_error Virginity::MergeError
  end

  specify "trying to break the name" do
    v = Vcard.new
    v.name.given = "Jason"
    v.name.given.should == "Jason"
    v.name.given = "Ja;son"
    v.name.given.should == "Ja;son"
    v.name.to_s.should_not include "/"
  end

  specify "empty?" do
    v = Vcard.new
    v.name.empty?.should == true

    v.name.given = "Jason"
    v.name.empty?.should == false
    v.name.given = ""
    v.name.empty?.should == true

    v.name.family = "Jason"
    v.name.empty?.should == false
    v.name.family = ""
    v.name.empty?.should == true

    v.name.additional = "Jason"
    v.name.empty?.should == false
    v.name.additional = ""
    v.name.empty?.should == true

    v.name.prefix = "Jason"
    v.name.empty?.should == false
    v.name.prefix = ""
    v.name.empty?.should == true

    v.name.suffix = "Jason"
    v.name.empty?.should == false
    v.name.suffix = ""
    v.name.empty?.should == true
  end
end


describe "formatted name" do
  before do
    @v = Vcard.new
  end

  specify "fn should initially be empty" do
    @v.name.formatted.should be_empty
  end

  specify "fn with a N-field set" do
    @v.name.given = "Bart"
    @v.name.formatted.should == "Bart"
  end

  specify "fn with a ORG-field set" do
    @v.add("ORG") { |x| x.orgname = "Wiegman Inc." }
    @v.name.formatted.should == "Wiegman Inc."
  end

  specify "fn with a N and ORG-field set" do
    @v.name.given = "Bart"
    @v.add("ORG") { |x| x.orgname = "Wiegman Inc." }
    @v.name.formatted.should == "Bart"
  end

  specify "fn with a N and email set" do
    @v.name.given = "Bart"
    @v.add("EMAIL") { |x| x.address = "bart@soocial.com" }
    @v.name.formatted.should == "Bart"
  end

  specify "fn with a N and a NICKNAME and email set" do
    @v.name.given = "Bart"
    @v.name.family = "Wiegman"
    @v.name.add_nickname "bartjo"
    @v.add("EMAIL") { |x| x.address = "bart@soocial.com" }
    @v.name.formatted.should == "Bart Wiegman"

    @v.name.generate_fn.should == "Bart Wiegman"
    @v.name.generate_fn(:include_nickname => true).should == "Bart \"bartjo\" Wiegman"
  end


  specify "fn with only email set" do
    @v.add("EMAIL") { |x| x.address = "bart@soocial.com" }
    @v.name.formatted.should == "bart@soocial.com"
  end

  specify "fn with only tel set" do
    @v.add("TEL") {|x| x.number = "0612341234" }
    @v.name.formatted.should == "0612341234"
  end

  specify "fn with email and telelephone set" do
    @v.add("TEL") {|x| x.number = "0612341234" }
    @v.add("EMAIL") { |x| x.address = "bart@soocial.com" }
    @v.name.formatted.should == "bart@soocial.com"
  end

  specify "fn with impp set" do
    @v.add("IMPP") { |x| x.scheme = "msn"; x.address = "bart@soocial.com" }
    @v.name.formatted.should == "bart@soocial.com"
  end

  specify "fn with telelephone and impp set" do
    @v.add("TEL") {|x| x.number = "0612341234" }
    @v.add("IMPP") { |x| x.scheme = "msn"; x.address = "bart@soocial.com" }
    @v.name.formatted.should == "bart@soocial.com"
  end

  # n > org > email > tel > impp

end
