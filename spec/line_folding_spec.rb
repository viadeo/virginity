require "#{File.dirname(__FILE__)}/spec_helper"

describe "Line Folding" do

  def create_vcard(len)
    Vcard.new.tap do |v|
      v.add("TEL") { |tel| tel.number = "2"*len }
    end
  end

  specify "fold this" do
    (0..100).each do |len|
      v = create_vcard(len).to_s
#       puts len, v
      lambda { Vcard.from_vcard(v) }.should_not raise_error
      v.should_not include(" \n") # we don't like spurious empty lines.
    end
  end

end
