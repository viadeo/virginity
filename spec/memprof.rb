$:.unshift "/home/tijn/soocial/lib/topdown/lib"
require "#{File.dirname(__FILE__)}/spec_helper"
require 'memprof'


context "Virginity::Field" do
  specify "params interface with a param" do
    Memprof.start
    invalid = ContentLine.from_line("FOO;baz:bar")
    x = ContentLine.from_line("FOO;TYPE=baz:bar")
    y = ContentLine.from_line("FOO;TYPE=baz:bar")
    z = ContentLine.from_line("foo;TYPE=baz:bar")
    Memprof.stats
    Memprof.stop

    x.should == y
    x.should == z
  end
end
