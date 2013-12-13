# -*- encoding: utf-8 -*-
require "#{File.dirname(__FILE__)}/spec_helper"

describe "merging" do
  before do
    @one = Vcard.from_vcard <<-end_vcard
BEGIN:VCARD
N:McSoocial;John;Paul;;Sr.
FN:John McSoocial
ORG:Soocial
VERSION:3.0
END:VCARD
end_vcard
    @two = Vcard.from_vcard <<-end_vcard
BEGIN:VCARD
N:McSoocial;John;Paul ;;Sr.
FN:John McSoocial
ORG:Soocial
VERSION:3.0
END:VCARD
end_vcard
  # --^ from #1208 Mingle bot fials on space after name
  end

  specify "should simply work for equal names" do
    lambda { @one.name.merge_with!(@one.dup.name) }.should_not raise_error
    @one.name.merge_with!(@one.dup.name).given.should == "John"
  end

  specify "should also work for names with extra whitespace" do
    lambda { @one.name.merge_with!(@two.name) }.should_not raise_error
    @one.name.merge_with!(@two.name).given.should == "John"
    @one.name.merge_with!(@two.name).additional.should == "Paul"
  end

end
