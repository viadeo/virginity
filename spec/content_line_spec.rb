require "spec_helper"

describe Virginity::ContentLine do

  specify "params interface without any params" do
    x = ContentLine.from_line("Monkey.FOO:bar")
    x.group.should == "Monkey"
    x.params.should == []
    x.params.should be_empty
  end

  specify "params interface without any params" do
    x = ContentLine.from_line("FOO:bar")
    x.params.should == []
    x.params.should be_empty
  end

  specify "params interface with a param" do
    x = ContentLine.from_line("FOO;TYPE=baz:bar")
    x.params.should_not == []
    x.params.should_not be_empty
    types = x.params.select {|p| p.key == 'TYPE'}.map{|t| t.value }
    types.should_not be_nil
    types.should include "baz"
    types.should == ["baz"]
  end

  specify "params interface case INsensitivity" do
    x = ContentLine.from_line("FOO;TYPE=baz:bar")
    x.params.should_not == []
    x.params.should_not be_empty
    types = x.params.select {|p| p.key == 'TYPE'}
    types.should == x.params("TYPE")
    types.should == x.params("type")
    types.should == x.params("tYpE")
  end

  specify "params interface with a param" do
    x = ContentLine.from_line("FOO;TYPE=baz:bar")
    y = ContentLine.from_line("FOO;TYPE=baz:bar")
    z = ContentLine.from_line("foo;TYPE=baz:bar")
    x.should == y
    x.should == z
  end

  specify "params interface with a param" do
    x = ContentLine.from_line("FOO;TYPE=BAR:foo")
    y = ContentLine.from_line("FOO;TYPE=BAZ:foo")
    x.params.size.should == 1
    y.params.size.should == 1
    x.merge_with! y
    x.params.size.should == 2
    x.param_values.sort.should == %w(BAR BAZ)
  end

  specify "sorting content lines" do
    x = ContentLine.from_line("FOO;TYPE=BAR:foo")
    y = ContentLine.from_line("FOO;TYPE=BAZ:foo")
    [x, y].sort.last.should == y
    [y, x].sort.last.should == y
  end

  specify "content line with a colon in the middle of param value" do
    x = ContentLine.from_line(%(FOO;TYPE="BAR:BAZ":foo))
    x.params.size.should == 1
    x.param_values.first.should == %(BAR:BAZ)
    x.value.should == "foo"
  end

  specify "parse empty param" do
    x = ContentLine.from_line("TEL;TYPE=,CELL:0692775328")
    x.name.should == "TEL"
    x.params.size.should == 1
    x.params.last.value.should === "CELL"
  end

  it "should print something better than inspect on #pretty_print" do 
    x = ContentLine.from_line("TEL;TYPE=,CELL:0692775328")
    io = StringIO.new
    PP.pp(x, io)
    io.string.strip.should_not == x.inspect.strip
  end

  # it "should print a nice diff when this test fails" do 
  #   x = ContentLine.from_line("TEL;TYPE=CELL:000555")
  #   y = ContentLine.from_line("TEL;TYPE=HOME,FAX:000444")
  #   x.should == y
  # end
end
