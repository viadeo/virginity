# -*- encoding: utf-8 -*-
require "#{File.dirname(__FILE__)}/spec_helper"

describe "Virginity::Vcard21" do

  specify "difficult lines" do
    p = Vcard21::Parser.new("PHOTO;GIF;MIME:<<JOHNSMITH.part3.960129T083020.xyzMail@host3.com>\n")
    x = p.parse_item
    x.should_not be_nil
    x[:groups].should be_empty
    x[:value].should == "<<JOHNSMITH.part3.960129T083020.xyzMail@host3.com>"
  end

  specify "read a plain vcard" do
    p = Vcard21::Parser.new(File.read("#{VCARDS_ROOT}/johnsmith21.vcf"))
    lambda{ p.parse! }.should_not raise_error
  end

  specify "read a plain vcard" do
    p = Vcard21::Parser.new(File.read("#{VCARDS_ROOT}/martinstephen21.vcf"))
    lambda{ p.parse! }.should_not raise_error
  end

  specify "read a vcard with quoted printable values" do
    p = Vcard21::Parser.new(File.read("#{VCARDS_ROOT}/fake21.vcf"))
    lambda{ p.parse! }.should_not raise_error
  end

  specify "read a vcard with base64 values" do
    p = Vcard21::Parser.new(File.read("#{VCARDS_ROOT}/pci21.vcf"))
    lambda{ p.parse! }.should_not raise_error
  end

  specify "read a vcard with base64 values" do
    p = Vcard21::Parser.new(File.read("#{VCARDS_ROOT}/evamarie21.vcf"))
    lambda{ p.parse! }.should_not raise_error
#     p.stats_histogram.each do |x|
#       puts "#{x.first.inspect}: #{x.last}"
#     end
  end

  specify "read a vcard with an incomplete name values" do
    p = Vcard21::Parser.new(File.read("#{VCARDS_ROOT}/incomplete_n21.vcf"))
    lambda{ p.parse! }.should_not raise_error
    # puts Vcard.from_vcard(File.read("#{VCARDS_ROOT}/incomplete_n21.vcf"))
  end
end


describe "vCard 2.1" do
  specify "read this" do
    v = <<end_vcard
BEGIN:VCARD
VERSION:2.1
N:Smith;John;M.;Mr.;Esq.
TEL;WORK;VOICE;MSG:+1 (919) 555-1234
TEL;CELL:+1 (919) 554-6758
TEL;WORK;FAX:+1 (919) 555-9876
PHOTO;GIF;MIME:<<JOHNSMITH.part3.960129T083020.xyzMail@host3.com>
ADR;WORK;PARCEL;POSTAL;DOM:Suite 101;1 Central St.;Any Town;NC;27654
END:VCARD
end_vcard
    Vcard.from_vcard21(v)
  end

  specify "read this" do
    v = <<end_vcard
BEGIN:VCARD
VERSION:3.0
N:;;;;
ORG:Apple Computer Benelux BV;
item1.ADR;type=WORK;type=pref:;;Kosterijland 42;AJ Bunnik;;3981;Netherlands
item1.X-ABADR:nl
item2.URL;type=pref:http\://www.apple.nl
item2.X-ABLabel:_$!<HomePage>!$_
PHOTO;BASE64:
  TU0AKgAAAyiAP+BQOCQWDQeEQmFQuGQ2HQ+IRGJROKRWLReMRmNRuOR2PR+QSGRSOPPyTOZ1OxjM
  1pLZfsVtuBxySaTWHvF5vVkNBqqlZrlTrFbqqfthvOKbUmlQN4PN6L1jMugrep1NZLtguR0uul12
  RvZ8PhhstoVWhWZbr5jsywPivW+PzFxqhZUCz3ehz9st+Z3C/Rp6vd8MFks60Whis1ovd8vm/4+L
  ul2O5YrpgYehMBkM2mvTIZ+LOJzOm0ZVgM5qtmcvbQa1+696PZ76vXv2Eu14PJmNNsNNtN7JO7a0
  yncF2u9423Wx+TPx0ZNlNFqrthslar5iddiLxispmtRsc93Pl9PuB7Xyvt3vJ575vVBlrVesOrsF
  ZLxgy5i2NoN1xnMxjHOWiLVmWaRrFcW5eroXDMKooS6FyV5cF8zRmmubpwG4cJyJWaT6wjB0HKIX
  MLHUdx4QGhbcHk7hlREvEYQeW8GQZGUbxioTtHIdB1uHFTVl4YkXxzGccSNIsjyUvDCGdALlubAx
  rSXJEqypK8ilyYRjq1HzXs+2seHWWBcl/LErSTNM0TWtBcGCYzjnjFR/vEY5nGnG01TPPc9KFCZf
  NEdM5oGaBrm27U+TZPtFUYYhmGi9NBoEX61xJRNL0WtBWFsXijKRSSB0RTNR0ZTBbvqcrJVAgb61
  NV1SPkYZ1OPVaBNNV9S1JGRZl4YTxVqf9eGFXFiTVBJem8cZz2BIRlTzXNoWLGcIu+bFgTsacyTN
  XVuWjWDsTjUBsG6cLqGTaV0LxBhkulJ8VRY3ZsRDbt02hEl4uU1zXnAcpz21euAQgur+Vmd7ltW+
  GA29ha0F0YZkTmaRsG5eeGXpi9GSlOb1nnYWFXrTZeYLUDUGzj+MRknZq0jSSnHrNxjZPi0qvrE8
  U2AgVknOVZaF1mUzp8XL3ZwgramgaxtZ/btHGjfOiIKtsLaVRhbmAYtw6ehacHrqVFwZhxkSlQpt
  2qtRmUtReYHOdZ26yiLAnwaOJvqVZal2+5g5VLrYnu9LauatrxXi7RWwVvF445t3FcXxnG8dx/Ic
  jyXJ8pyvLIIgIAANAQAAAwAAAAEAMAAAAQEAAwAAAAEAMAAAAQIAAwAAAAMAAAPKAQMAAwAAAAEA
  BQAAAQYAAwAAAAEAAgAAAREABAAAAAEAAAAIARUAAwAAAAEAAwAAARYABAAAAAEAAADjARcABAAA
  AAEAAAMgARoABQAAAAEAAAPQARsABQAAAAEAAAPYARwAAwAAAAEAAQAAASgAAwAAAAEAAgAAAAAA
  AAAIAAgACAAK/IAAACcQAAr8gAAAJxA=
X-ABShowAs:COMPANY
X-ABUID:5210D790-E172-489D-AA6F-C2B709B53F39\:ABPerson
END:VCARD
end_vcard
    Vcard.from_vcard21(v)
  end

  before do
    @vcards = Dir.glob("#{VCARDS_ROOT}/*21.vcf").map do |f|
      File.read(f)
    end
    @vcards.should_not be_empty
  end

  specify "it should be able to load every vcard" do
    @vcards.each do |vcard|
      x = Vcard.from_vcard21(vcard)
      (x/"N").should_not be_empty
    end
  end
end


describe "encoding base64" do
  before do
    @vcf = <<end_vcard
BEGIN:VCARD
VERSION:2.1
N:;;;;
ORG:Apple Computer Benelux BV;
PHOTO;ENCODING=BASE64:#{Base64.encode64("123")}
END:VCARD
end_vcard
  end

  specify "read the vcard" do
    vcard = Virginity::Vcard.from_vcard(@vcf)
    vcard.find_first(:name => 'PHOTO').binary.should == "123"
  end

end

describe "converting from vCard 2.1 to Virginity::Vcard " do
  specify "read a vcard with quoted printable values" do
    aurora = File.read("#{VCARDS_ROOT}/aurora21.vcf")
    (aurora =~ /QUOTED-PRINTABLE/i).should_not be_nil
    v = Vcard.from_vcard21(aurora)
    (v.to_s =~ /QUOTED-PRINTABLE/i).should be_nil
  end

  it "should make a vCard 3.0 from it" do
    eva = Vcard.from_vcard21(File.read("#{VCARDS_ROOT}/evamarie21.vcf"))
    (eva/"VERSION:3.0").should_not be_empty
  end
end


describe "converting from vCard 2.1 to 3.0 reading a vcard with a photo" do
  specify "base64 ===> b" do
    pci= File.read("#{VCARDS_ROOT}/pci21.vcf")
    (pci.to_s =~ /BASE64/i).should_not be_nil
    v = Vcard.from_vcard21(pci)
    (v.to_s =~ /BASE64/i).should be_nil
  end
end


describe "converting from vCard 2.1 to 3.0 reading a vcard with a charset" do
  include Encodings

  specify "charset == 'UTF-8'" do
    aurora = File.read("#{VCARDS_ROOT}/aurora21.vcf")
    (aurora =~ /CHARSET/i).should_not be_nil
    v = Vcard.from_vcard21(aurora)
    (v.to_s =~ /CHARSET/i).should be_nil
    (v/'NOTE').first.raw_value.should include "opérationnel"
  end

  specify "charset != 'UTF-8'" do
    aurora = File.read("#{VCARDS_ROOT}/fake21.vcf")
    (aurora =~ /CHARSET/i).should_not be_nil
    v = Vcard.from_vcard21(aurora)
    v.to_vcard21
    (v.to_s =~ /CHARSET/i).should be_nil
    v.name.formatted.should == "太 テト"
    v.to_s.encoding.should == Encoding::UTF_8 if "Ruby1.9".respond_to? :encoding
  end
end


#
describe "writing a vcard21" do
  specify "" do
    Dir.glob("#{VCARDS_ROOT}/*.vcf").each do |f|
      vcard = File.read(f)
      support = Vcard.from_vcard(vcard)
      lambda { support.to_vcard21 }.should_not raise_error
      lambda { Vcard.from_vcard21(support.to_vcard21) }.should_not raise_error
      lambda { Vcard.from_vcard21(support.to_vcard21(:vcard21_omit_type_if_knowntype => true)) }.should_not raise_error
    end
  end

  # https://soocial.lighthouseapp.com/projects/10687/tickets/1032-havana-sometimes-doesnt-encode-vcards-correctly
  specify "read the vcard from ticket #1032 and output it correctly with a CHARSET param" do
    zeus = File.read("#{VCARDS_ROOT}/zeus21.vcf")
    p = Vcard21::Parser.new(zeus)
    lambda { p.parse! }.should_not raise_error
    v = Vcard.from_vcard21(zeus)
    v.to_s.should_not include "CHARSET"
    v.to_vcard21.should include "CHARSET"
  end
end

describe "reading this vcard" do
  specify "downcase paramkeys" do
    michael = <<end_vcard
BEGIN:VCARD
VERSION:2.1
N;CHARSET=UTF-8:Arrington;Michael;;;
FN;CHARSET=UTF-8:Michael Arrington
TEL;type=TELEX;type=pref:+4523252632
END:VCARD
end_vcard
    lambda { Vcard.from_vcard(michael) }.should_not raise_error
    versions = Vcard.from_vcard(michael)/"VERSION"
    versions.size.should == 1
    versions.first.raw_value.should == "3.0"
  end
end


describe "encoding=8bit param" do
  before do
    @annette = <<end_vcard
BEGIN:VCARD
VERSION:2.1
N;CHARSET=UTF-8;ENCODING=8BIT:Jansen;Annette
TEL:123
FN;CHARSET=UTF-8;ENCODING=8BIT:Annette Jansen
END:VCARD
end_vcard
  end

  specify "should be read correctly" do
    lambda { Vcard.from_vcard21(@annette) }.should_not raise_error
    v = Vcard.from_vcard21(@annette)
    v.to_s.should include "ENCODING=8BIT"
  end

  specify "should be removed with a cleaner" do
    v = Vcard.from_vcard21(@annette)
    v.clean!
    v.to_s.should_not include "ENCODING=8BIT"
  end

end


describe "line folding in vCard 2.1" do
 before :each do
   @yorick = <<end_vcard
BEGIN:VCARD
VERSION:2.1
N:Powell;Yorick;;;
FN:Yorick Powell
ORG;CHARSET=UTF-8:Powell Graphic Design;
ADR;WORK;X-Synthesis-Ref0:;;Velperweg 92wortstje;Arnhem;;6824 HL;The
 Netherlands
ADR;HOME;X-Synthesis-Ref1:;;Oude Powellstraat 119;Nimwegen;;6515 EB;The
 Netherlands
URL;PREF;X-Synthesis-Ref0:http://www.google.nl
END:VCARD
end_vcard

   @nokia = <<end_vcard
BEGIN:VCARD
VERSION:2.1
N:Nokia;Bert;;;
ADR;HOME:;;Oude Groenestraatttttttttttttttttt 141;Nijmegen;;6515
  EB;The Netherlands
END:VCARD
end_vcard

  end

  specify "should regard newline-space as a space" do
    v = Vcard.from_vcard21(@yorick)
    v.clean!
    v.addresses.first.country.should == "The Netherlands"
    v.addresses.last.country.should == "The Netherlands"
  end

  specify "should be able to totally ignore newline-space for some nokia's" do
    v = Vcard.from_vcard21(@nokia, { :vcard21_line_folding_with_extra_space => true })
    v.clean!
    v.addresses.first.postal_code.should == "6515 EB"
  end
end


describe 'shorthand params' do
  before :all do
    # it seems some people send us shorthand params where a comma separated list of values follows a key in vcard2.1 which I think is not according to the specs
    @weird = <<end_vcard
BEGIN:VCARD
VERSION:2.1
TEL;TYPE=fax,work:+86-129124781
TEL;TYPE=,CELL:061111
END:VCARD
end_vcard
  end

  specify "shorthand params" do
    lambda { Vcard.from_vcard21(@weird) }.should_not raise_error
  end
end


describe 'illegal but commonly used shorthand params' do
  before :all do
    # it seems some people send us shorthand params where a comma separated list of values follows a key in vcard2.1 which I think is not according to the specs
    @weird = <<end_vcard
BEGIN:VCARD
VERSION:2.1
N:Philleas;Philip;;;
EMAIL;INTERNET:info@example.com
END:VCARD
end_vcard
  end

  specify "shorthand params" do
    lambda { Vcard.from_vcard21(@weird) }.should_not raise_error
  end
end


describe 'empty param list' do
  specify "shorthand params" do
    s = "BEGIN:VCARD\r\nVERSION:2.1\r\nN:Bernadt;;;;\r\nFN:Bernadt\r\nTEL;:+491815357178\r\nEND:VCARD\r"
    lambda { Vcard.from_vcard21(s) }.should_not raise_error
  end
end


describe 'encode as quoted_printable' do
  before :each do
    @s = "BEGIN:VCARD\nN:Ельцина;Þrúðr;;;\nVERSION:3.0\nFN:Þrúðr Ельцина\nORG:Ζεύς Inc.\nTEL:555-0135\nEMAIL;TYPE=HOME:Þrúðr@Ельцина.com\nURL:www.Ельцина.com\nADR:;;Ельцина Street 18;Þrúðr Town;;4048 AX;Never Neverland\nEND:VCARD\n"
    @v = Vcard.from_vcard(@s)
  end

  specify 'should be encoded correctly when converted to 2.1' do
    encoded = @v.to_vcard21
    encoded.should include 'ENCODING=QUOTED-PRINTABLE'
    lambda { Vcard.from_vcard21(encoded) }.should_not raise_error
  end

  specify "should not crap out on this" do
    vcard = "BEGIN:VCARD\nADR;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE;HOME;TYPE=OTHER;PREF;X-FORMAT=de:=\r\n;;Loristrasse=207;M=C3=BCnchen;;80335;\nEND:VCARD"
    v = Vcard.from_vcard21(vcard)
    lambda { v.to_vcard21 }.should_not raise_error
  end

end
