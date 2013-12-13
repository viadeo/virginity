# this spec only makes sense for ruby 1.9
if defined? Encoding::UTF_8
  require "#{File.dirname(__FILE__)}/spec_helper"
  require 'rubygems'
  require 'active_support/core_ext'

  describe "encodings" do
    specify 'round trips binary data' do
      v = Vcard.new
      v.add("PHOTO") do |p|
        p.params << Param.new('TYPE', 'JPG')
        p.binary = "\x01\x02\x03\xFF".force_encoding(Encoding::BINARY)
      end

      v2 = Vcard.new(v.to_s)
      (v / "PHOTO").first.binary.should == "\x01\x02\x03\xFF".force_encoding(Encoding::BINARY)
    end

    specify "to_s returns utf-8" do
      Encoding.compatible?(Vcard.new.to_s.encoding, Encoding::UTF_8).should == Encoding::UTF_8
    end
  end

end
