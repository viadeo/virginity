require "#{File.dirname(__FILE__)}/spec_helper"

describe "IMPP fields" do

  specify "an empty IMPP field" do
    x = Field.named("IMPP")
    x.to_s.should == "IMPP:"
    x.params.should be_empty
  end

  specify "an empty IMPP field with a value" do
    x = Field.named("IMPP")
    x.text = "lalala"
    x.raw_value.should == "lalala"
    x.to_s.should == "IMPP:lalala"
    x.params.should be_empty
    x.scheme.should == ""
    x.address.should == "lalala"
  end

  specify "an empty IMPP field with an address" do
    x = Field.named("IMPP")
    x.address = "lalala"
    x.raw_value.should == ":lalala"
    x.to_s.should == "IMPP::lalala"
    x.params.should be_empty
    x.scheme.should == ""
    x.address.should == "lalala"
    x.address = "bibibi"
    x.address.should == "bibibi"
    x.scheme = "xmpp"
    x.address.should == "bibibi"
    x.scheme.should == "xmpp"
    x.to_s.should == "IMPP:xmpp:bibibi"
  end


  specify "an empty IMPP field without an address" do
    x = Field.named("IMPP")
    x.address = ""
    x.raw_value.should == "" #since scheme AND address are empty
    x.to_s.should == "IMPP:"
    x.params.should be_empty
    x.scheme.should == ""
    x.address.should == ""
    # a field with just a scheme should have an empty value
    x.scheme = "msn"
    x.scheme.should == "msn"
    x.address.should == ""
    x.raw_value.should ==  "msn:"

    x.scheme = ""
    x.address = "blah:"
    x.text.should == ":blah:"
    x.scheme.should == ""
    x.address.should == "blah:"
    x.raw_value.should ==  ":blah:"
  end

end

describe "custom IMPP fields for OSX" do

  specify "OSX is using no text encoding" do
    s = "X-JABBER;TYPE=HOME,PREF:bartenator\barten40hotmail.com@jabber.server.domain"
    f = Field.from_line s
    f.to_impp.text.should == "xmpp:bartenator\barten40hotmail.com@jabber.server.domain"
    Field::CustomImField.from_impp(f.to_impp).should == f
    Field::CustomImField.from_impp(f.to_impp).to_s.should == s
  end

end
