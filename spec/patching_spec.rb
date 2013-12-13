require "#{File.dirname(__FILE__)}/spec_helper"

describe "Patching: diffing" do

  before :each do
    @v = Vcard.from_vcard <<-end_vcard
begin:vcard
n:Yeyo;Jan;;;
tel:1234567890
end:vcard
end_vcard
  end

  specify "no update" do
    w = @v.deep_copy
    diff = Vcard::Patching::diff(@v, w)
    diff.size.should == 0
  end

  specify "update number" do
    w = @v.deep_copy
    w.telephones.first.number = "1111 1111 11"
    diff = Vcard::Patching::diff(@v, w)
    diff.size.should == 2 # remove old nr, add new (NB this could be 1 update in the future)
  end

  specify "update label" do
    w = @v.deep_copy
    w.telephones.first.params << Param.new("TYPE", "HOME")
    diff = Vcard::Patching::diff(@v, w)
    diff.size.should == 1 # one update
  end

  specify "ignore case differences" do
    w = Vcard.from_vcard <<-end_vcard
BEGIN:VCARD
N:Yeyo;Jan;;;
TEL:1234567890
END:VCARD
end_vcard
    diff = Vcard::Patching::diff(@v, w)
    diff.should be_empty
  end
end

describe "Patching: patching" do

  before :each do
    @jan1 = Vcard.from_vcard <<-end_vcard
begin:vcard
n:Yeyo;Jan;;;
tel:1234567890
end:vcard
end_vcard
    @jan2 = Vcard.from_vcard <<-end_vcard
begin:vcard
n:Yeyo;Jan;;;
tel:1234567890
tel:321
end:vcard
end_vcard

    @jan3 = Vcard.from_vcard <<-end_vcard
begin:vcard
n:Yeyo;Jan;;;
tel:1234567890
tel;TYPE=HOME,WORK,FAX:321
end:vcard
end_vcard

    @jan4 = Vcard.from_vcard <<-end_vcard
begin:vcard
n:Yeyo;Jan;;;
tel;TYPE=HOME,WORK,FAX:321
end:vcard
end_vcard

    @jan10 = Vcard.from_vcard <<-end_vcard
begin:vcard
n:Yeyo;Jan;;;
tel:1234567890
email:jan@example.com
url:http://jan.nl
url:http://janneman.nl
end:vcard
end_vcard
  end

  specify "patching" do
    diff = Vcard.diff(@jan1, @jan2)
    x = @jan1.patch!(diff)
    x.should == @jan1 # patch! should return self
    @jan1.should == @jan2
  end

  specify "patching a later version" do
    diff = Vcard.diff(@jan2, @jan3)
    diff.to_s.should include "Update"
    (@jan2/"TEL:321").first.params.should_not include Param.new("TYPE", "FAX")
    @jan2.patch!(diff)
    (@jan2/"TEL:321").first.params.should include Param.new("TYPE", "FAX")
  end

  specify "patching a later version" do
    diff = Vcard.diff(@jan1, @jan2)
    (@jan10/"TEL:321").should be_empty
    @jan10.patch!(diff)
    (@jan10/"TEL:321").size.should == 1
  end

  specify "patching a much later version" do
    diff = Vcard.diff(@jan1, @jan3)
    diff.to_s.should include "Add"
    (@jan10/"TEL:321").should be_empty
    @jan10.patch!(diff)
    (@jan10/"TEL:321").first.params.should include Param.new("TYPE", "HOME")
    (@jan10/"TEL:321").first.params.should include Param.new("TYPE", "WORK")
    (@jan10/"TEL:321").first.params.should include Param.new("TYPE", "FAX")
  end

  specify "patching a much later version with a remove" do
    diff = Vcard.diff(@jan1, @jan4)
    diff.to_s.should include "Remove"
    (@jan10/"TEL:321").should be_empty
    (@jan10/"TEL:1234567890").should_not be_empty
    @jan10.patch!(diff)
    (@jan10/"TEL:321").first.params.should include Param.new("TYPE", "HOME")
    (@jan10/"TEL:321").first.params.should include Param.new("TYPE", "WORK")
    (@jan10/"TEL:321").first.params.should include Param.new("TYPE", "FAX")
    (@jan10/"TEL:1234567890").should be_empty
  end

end

describe "Patching organizations" do
  before do
    @v0 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      ORG:A
      END:VCARD
    END_OF_VCARD
    @v1 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      ORG:A;;
      END:VCARD
    END_OF_VCARD
  end

  specify "diffing with the vcard that is different by empty unit1 and unit2 in ORG" do
    Virginity::Vcard.diff(@v0, @v1).should be_empty
  end

  specify "removes A when patching for -A;;" do
    result = @v0.patch!(Virginity::Vcard.diff(@v1, Virginity::Vcard.new(Virginity::Vcard::EMPTY)))
    result.organizations.should be_empty
  end
end

describe "Patching categories" do
  before do
    @v0 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      CATEGORIES:B,A
      END:VCARD
    END_OF_VCARD
    @v1 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      CATEGORIES:A,B
      END:VCARD
    END_OF_VCARD
  end

  specify "ignores the order of categories" do
    result = @v0.patch!(Virginity::Vcard.diff(@v1, Virginity::Vcard.empty))
    result.category_values.sort.should be_empty
  end

  specify "removes categories even if to the original vcard a new category was added" do
    @v0.add_category('C')
    result = @v0.patch!(Virginity::Vcard.diff(@v1, Virginity::Vcard.empty))
    result.category_values.sort.should == ['C']
  end
end


describe "Patching params" do
  before do
    @v0 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      TEL:123
      END:VCARD
    END_OF_VCARD

    @v1 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      TEL;type=home:123
      END:VCARD
    END_OF_VCARD

    @v2 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      TEL;type=cell:06123
      END:VCARD
    END_OF_VCARD
  end

  specify "should be ONE update" do
    diff = Virginity::Vcard.diff(@v0, @v1)
    diff.size.should == 1
  end

  specify "should work (add a type=home)" do
    result = @v0.patch!(Virginity::Vcard.diff(@v0, @v1))
    result.telephones.size.should == 1
    result.telephones.first.params.should_not be_empty
  end

  specify "should add a field if it is not there" do
    result = Vcard.empty.patch!(Virginity::Vcard.diff(@v0, @v1))
    result.telephones.size.should == 1
    result.telephones.first.params.should_not be_empty
    result.telephones.first.number.should == "123"
  end

  specify "should add a field if it is not there" do
    result = @v2.patch!(Virginity::Vcard.diff(@v0, @v1))
    result.telephones.size.should == 2
    result.telephones.last.params.should_not be_empty
    result.telephones.last.number.should == "123"
  end
end

describe 'Patching empty name' do
  before do
    @v0 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      N:;;;
      END:VCARD
    END_OF_VCARD

    @v1 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      END:VCARD
    END_OF_VCARD
  end

  specify "should see no difference" do
    Virginity::Vcard.diff(@v0, @v1).size.should == 0
  end
end

describe 'Patching with params in different order' do
  before do
    @v0 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      TEL;TYPE=HOME;TYPE=WORK;FOO=BAR:123
      END:VCARD
    END_OF_VCARD

    @v1 = Virginity::Vcard.new <<-END_OF_VCARD.gsub(/^\s+/, '')
      BEGIN:VCARD
      VERSION:3.0
      TEL;TYPE=WORK;FOO=BAR;TYPE=home:123
      END:VCARD
    END_OF_VCARD
  end

  specify "should see no difference" do
    Virginity::Vcard.diff(@v0, @v1).size.should == 0
  end
end
