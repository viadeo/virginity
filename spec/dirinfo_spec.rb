require "#{File.dirname(__FILE__)}/spec_helper"

describe "Folding" do
  specify "folding should always be revertible" do
    s = File.read("#{VCARDS_ROOT}/support.vcf")
    x = LineFolding::unfold(LineFolding::fold(s))
    x.should == LineFolding::unfold(s)
  end
end

describe "Virginity::DirectoryInformation" do
  before do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
  end

  specify "read vcards" do
    lambda { DirectoryInformation.new(@jason_vcf) }.should_not raise_error
  end
end


describe "adding and removing lines" do
  before do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
    @jason = DirectoryInformation.new(@jason_vcf)
  end

  specify "should contain the added line" do
    @jason.lines << "FOO:bar"
    @jason.lines.any? {|x| x.to_s == "FOO:bar" }.should == true
    @jason.to_s.should include "FOO:bar"
  end

  specify "should not contain the removed line" do
    l = @jason.lines.pop
    @jason.lines.any? {|x| x == l }.should == false
    @jason.to_s.should_not include "FOO:bar"
  end

  specify "should contain the added line" do
    @jason << "FOO:bar"
    @jason.lines.any? {|x| x.to_s == "FOO:bar" }.should == true
    @jason.to_s.should include "FOO:bar"
  end

  specify "should contain the added contentline" do
    @jason << ContentLine.from_line("FOO:bar")
    @jason.lines.any? {|x| x.to_s == "FOO:bar" }.should == true
    @jason.to_s.should include "FOO:bar"
  end

  specify "should be able to remove a contentline" do
    beg = "BEGIN:VCARD"
    @jason.to_s.should include beg
    @jason.delete(*@jason/beg)
    @jason.to_s.should_not include beg
    fn = "FN:Jason"
    @jason.to_s.should include fn
    @jason.delete(ContentLine.from_line(fn))
    @jason.to_s.should_not include fn
  end

  specify "should be able to remove multiple lines" do
    beg = "BEGIN:VCARD"
    fn = "FN:Jason"
    @jason.to_s.should include beg
    @jason.to_s.should include fn
    @jason.delete((@jason/beg).first, (@jason/fn).first)
    @jason.to_s.should_not include beg
    @jason.to_s.should_not include fn
  end

  specify "should be able to remove multiple lines and return the deleted lines" do
    beg = "BEGIN:VCARD"
    fn = "FN:Jason"
    @jason.to_s.should include beg
    @jason.to_s.should include fn
    deleted = @jason.delete((@jason/beg).first, (@jason/fn).first)
    deleted.map {|x| x.to_s }.should == [beg, fn]
    deleted = @jason.delete((@jason/beg).first, (@jason/fn).first)
    deleted.should == []
  end

  specify "should not complain about missing lines when deleting" do
    beg = "BEGIN:VCARD"
    fn = "FN:Jason"
    blah = "BLAH:a field that is not present in @jason"
    @jason.to_s.should include beg
    @jason.to_s.should include fn
    @jason.to_s.should_not include blah
    lambda { @jason.delete(*[@jason/beg, @jason/fn, @jason/blah].flatten) }.should_not raise_error
    @jason.to_s.should_not include beg
    @jason.to_s.should_not include fn
  end


end


describe "inspect should provide useful information" do
  specify "should be unique (include the object_id)" do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
    jason1 = DirectoryInformation.new(@jason_vcf)
    jason2 = DirectoryInformation.new(@jason_vcf)
    jason1.to_s.should == jason2.to_s
    jason1.inspect.should_not == jason2.inspect
    jason1.should == jason2
  end
end

describe "comparison" do
  before do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
    @jason1 = DirectoryInformation.new(@jason_vcf)
    @jason2 = DirectoryInformation.new(@jason_vcf)
    @jan = DirectoryInformation.new <<end_vcard
BEGIN:VCARD
N:Visser;Jan;;;
TEL;TYPE=CELL:12345
END:VCARD
end_vcard
  end

  specify "operator ==" do
    @jason1.should == @jason1
    @jason1.should.eql? @jason1
    @jason2.should == @jason2
    @jason2.should.eql? @jason2
    ( @jason1 == @jason2 ).should be_true
    ( @jason1.eql? @jason2 ).should be_true
    @jason1.should_not equal @jason2

    @jason1.should_not equal nil
    @jason1.should_not equal false
    @jason1.should_not equal 3
  end

  specify "operator == for shuffled lines" do
    @jason2.lines.push << @jason2.lines.shift
    @jason1.should == @jason1
    @jason1.should.eql? @jason1
    @jason2.should == @jason2
    @jason2.should.eql? @jason2
    ( @jason1 == @jason2 ).should be_true
    ( @jason1.eql? @jason2 ).should be_true
    @jason1.should_not equal @jason2
  end

  specify "subset?" do
    @jan.subset_of?(@jan).should be_true # it's not a "proper subset" but it's still a subset (http://en.wikipedia.org/wiki/Subset)
  end

  specify "subset? (params removed)" do
    @jan2 = DirectoryInformation.new(@jan.to_s)
    @jan2.first_match('TEL').params.clear
    @jan2.subset_of?(@jan).should be_true
    @jan2.superset_of?(@jan).should be_false

    @jan.subset_of?(@jan2).should be_false
    @jan.superset_of?(@jan2).should be_true
  end

  specify "subset? (field added)" do
    @jan2 = DirectoryInformation.new(@jan.to_s)
    @jan2 << "EMAIL:jan@soocial.com"
    @jan2.subset_of?(@jan).should be_false
    @jan2.superset_of?(@jan).should be_true

    @jan.subset_of?(@jan2).should be_true
    @jan.superset_of?(@jan2).should be_false
  end

end
