require "#{File.dirname(__FILE__)}/spec_helper"

describe "Virginity::Param" do
  specify "equals-operator" do
    Param.new("foo", "bar").should == Param.new("foo", "bar")
    Param.new("foo", "bar").should_not == Param.new("foo", "baz")
    Param.new("foo", "bar").should_not == Param.new("foz", "bar")
    Param.new("foo", "bar").should_not == Param.new("foz", "baz")
  end

  specify "spaceship-operator" do
    ( Param.new("foo", "bar") <=>  Param.new("foo", "bar") ).should == 0
    ( Param.new("foo", "bar") <=>  Param.new("foo", "baz") ).should < 0
    ( Param.new("foo", "bar") <=>  Param.new("foz", "bar") ).should < 0
    ( Param.new("foo", "bar") <=> Param.new("foz", "baz") ).should < 0
    ( Param.new("foz", "baz") <=> Param.new("foo", "bar") ).should > 0
  end

  specify "encoding" do
    lambda{ Param.new("foo", "bar").to_s }.should_not raise_error
    lambda{ Param.new("foo", "\"").to_s }.should_not raise_error
    lambda{ Param.new("foo", "\n").to_s }.should_not raise_error
    lambda{ Param.new("fo+o", "bar").to_s }.should raise_error
    lambda{ Param.new("fo o", "bar").to_s }.should raise_error
    Param.new("foo", ";").to_s.should include("\\;")
    Param.new("foo", ";").to_s.should include("\"") # since the value should be quoted
    Param.new("foo", "a").to_s.should_not include("\"")
    Param.new("foo", ";").to_s.should include("\"")
    Param.new("foo", ",").to_s.should include("\"")
    Param.new("foo", "\"").to_s.should include("\"")
    Param.new("foo", "\n").to_s.should include("\"")
    Param.new("foo", "\n").to_s.should_not include("\n")
  end

  specify "every encoded param should be decodable" do

    def test_reencoding(key, value)
#       puts "in: #{key.inspect}, #{value.inspect}"
#       puts "param: #{Param.new(key, value).to_s}"
#       puts "param: #{Param.new(key, value).to_s.inspect}"
#       puts "reload: #{Param.params_from_string(";"+Param.new(key, value).to_s)}"
      list = ";" + Param.new(key, value).to_s + ":"
      Param.params_from_string(list).should == [Param.new(key, value)]
    end

    test_reencoding("TYPE", "bar")
    test_reencoding("TYPE", "bar\"quote")
    test_reencoding("TYPE", "foo\nbar")
    test_reencoding("TYPE", ";n")
    test_reencoding("TYPE", ";\",';\"\"n")
  end

end

describe "Virginity::Param list" do
  before do
    # @wrong = "TYPE=FOO,BAR;QUOTED-PRINTABLE"
    @right = ";TYPE=FOO,BAR;ENCODING=QUOTED-PRINTABLE:"
  end

  specify "decoding" do
    params = Param.params_from_string(@right)
    params.size.should == 3
    params.sort.first.key.should == "ENCODING"
    simple = Param.simple_params_to_s(params)
    complex = Param.params_to_s(params)
    simple = Param.params_from_string(simple + ":")
    complex = Param.params_from_string(complex + ":")
    simple.sort.map(&:to_s).should == complex.sort.map(&:to_s)
  end

  it "should know that param-keys are case insensitive" do
    params = Param.params_from_string(@right)
    encoding = params.sort.first
    encoding.key.should == "ENCODING"
    encoding.has_key?("ENCODING").should be_true
    encoding.has_key?("encoding").should be_true
    encoding.has_key?("EncOdIng").should be_true
    encoding.has_key?("TYPE").should be_false
    encoding.has_key?("foo").should be_false
  end
end
