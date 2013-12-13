# -*- encoding: utf-8 -*-
require "#{File.dirname(__FILE__)}/spec_helper"

describe Virginity::Vcard do
  before do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
  end

  specify "read vcards" do
    lambda { Virginity::Vcard.new(@jason_vcf) }.should_not raise_error
  end

  specify "read vcards" do
    lambda { Virginity::Vcard.parse(@jason_vcf) }.should_not raise_error
  end

  specify "read this" do
  vcard = <<end_vcard
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
    lambda { Virginity::Vcard.parse(vcard) }.should_not raise_error
  end

  specify "read small list" do
    Virginity::Vcard.vcards_in_list(File.read("#{VCARDS_ROOT}/support.vcf")).size.should == 1
    lambda { Virginity::Vcard.list(File.read("#{VCARDS_ROOT}/support.vcf")) }.should_not raise_error
    Virginity::Vcard.list(File.read("#{VCARDS_ROOT}/support.vcf")).size.should == 1
  end

  specify "read larger list" do
    lambda { Virginity::Vcard.list(File.read("#{VCARDS_ROOT}/list/list.vcf")) }.should_not raise_error
    Virginity::Vcard.vcards_in_list(File.read("#{VCARDS_ROOT}/list/list.vcf")).size.should == 11
    list = Virginity::Vcard.list(File.read("#{VCARDS_ROOT}/list/list.vcf"))
    list.size.should == 11
    list.last.name.formatted.should == "Ζεύς Carreño Quiñones"
  end

  specify "read from file" do
    lambda { Virginity::Vcard.load_all_from("#{VCARDS_ROOT}/support.vcf") }.should_not raise_error
  end

  it "should print something more useful than #inspect on #pretty_print" do
    support = Virginity::Vcard.parse File.read("#{VCARDS_ROOT}/support.vcf")
    io = StringIO.new
    PP.pp(support, io)
    io.string.strip.should_not == support.inspect.strip
  end

  # it "should print a nice diff when this test fails" do
  #   support = Virginity::Vcard.parse File.read("#{VCARDS_ROOT}/support.vcf")
  #   a = support.deep_copy
  #   a << "TEL:000000000"
  #   support.should == a
  # end
end


describe "Virginity::Vcard adding and removing lines" do
  before do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
    @jason = Virginity::Vcard.new(@jason_vcf)
    @foo = ContentLine.from_line("FOO:bar")
  end

  specify "should contain the added line" do
    @jason << "FOO:bar"
    @jason.lines.any? {|x| x == @foo }.should == true
    @jason.to_s.should include "FOO:bar"
  end

  specify "should not contain the removed line" do
    l = @jason.lines.pop
    @jason.lines.any? {|x| x == l }.should == false
    @jason.to_s.should_not include "FOO:bar"
  end

  specify "should contain the added line" do
    @jason << "FOO:bar"
    @jason.lines.any? {|x| x == @foo }.should == true
    @jason.to_s.should include "FOO:bar"
  end

  specify "should contain the added contentline" do
    @jason << Virginity::ContentLine.from_line("FOO:bar")
    @jason.lines.any? {|x| x == @foo }.should == true
    @jason.to_s.should include "FOO:bar"
  end

  specify "should be able to remove a contentline" do
    beg = "BEGIN:VCARD"
    @jason.to_s.should include beg
    @jason.delete(*@jason/beg)
    @jason.to_s.should_not include beg
    fn = "FN:Jason"
    @jason.to_s.should include fn
    @jason.delete(Virginity::ContentLine.from_line(fn))
    @jason.to_s.should_not include fn
  end
end


describe "Virginity::Vcard querying" do
  before do
    @jason_vcf = File.read("#{VCARDS_ROOT}/support.vcf")
    @jason_vcf.should_not be_empty
    @jason = Virginity::Vcard.new(@jason_vcf)
  end

  specify "should return an array of fields" do
    (@jason/"N").size.should == 1
    (@jason/"N").first.should be_kind_of Virginity::BaseField
  end

  specify "should work with name-queries" do
    (@jason/"N").size.should == 1
    (@jason/"N").first.raw_value.should include("Jason")
    (@jason/"PHOTO").size.should == 1
  end

  specify "querying by group" do
    (@jason/"x.N").size.should == 0
  end

  specify "querying by value" do
    (@jason/":Jason").size.should == 2 # the FN and NAME
    (@jason/":Jason").first.name.should == "FN"
    (@jason/":Jason").last.name.should == "NAME" # NAME is NOT a standard field!
    (@jason/":support@soocial.com").should == @jason/"EMAIL"
  end

  specify "querying by combinations" do
    (@jason/"FN:Jason").size.should == 1
    (@jason/"FN:Josan").size.should == 0
  end
end


describe "changing values" do
  specify "changing text (telnr)" do
    v = Virginity::Vcard.from_vcard21(File.read("#{VCARDS_ROOT}/aurora21.vcf"))
    (v/"TEL").should_not be_empty
    (v/"TEL").first.text.should == "+33620851986"
    (v/"TEL").first.text = "2222 22 2"
    (v/"TEL").first.text.should == "2222 22 2"
#     (v/"TEL").first.to_s.should include "2222 22 2"
#     v.to_s.should include "2222 22 2"
  end
end


describe "accepting vCards" do
  specify "with downcased field names" do
    v = <<end_vcal
begin:vcard
n:;Weirdo;;;
fn:
end:vcard
end_vcal
    lambda { Vcard.from_vcard(v) }.should_not raise_error
    Vcard.from_vcard(v).name.given.should == "Weirdo"
  end

  specify "but not weird things" do
    v = <<end_vcal
END:VCARD
N:;Weirdo;;;
FN:
BEGIN:VCARD
end_vcal
    lambda { Vcard.from_vcard(v) }.should raise_error Virginity::InvalidVcard
  end

  specify "no control chars allowed" do
    v = <<end_vcard
BEGIN:VCARD
VERSION:2.1
N:UBML;;;;
NOTE;ENCODING=QUOTED-PRINTABLE;CHARSET=UTF-8:United Business Media Limited is a global business media company. The Company informs markets and brings the world=19s buyers and sellers together through news distribution, at events, online, in print and through its business information products and services. It operates in two segments: B2B Distribution, Monitoring and Targeting and B2B Communities. The B2B Distribution, Monitoring and Targeting segment operates in the distribution, targeting and evaluation of company information. The B2B Communities segment operates in the provision of events, business information, marketing services, directories, Websites, magazines and trade press.In July 2009, it acquired Iasist. In December 2009, it acquired Virtual Press Office. In December 2009, it transfered its 70% interest in the China International Optoelectronic Expo (CIOE) trade show to eMedia Asia Ltd, the Company's joint venture with Global Sources, in which it has a 40% interest and Global Sources has a 60% interest.
END:VCARD
end_vcard
    lambda { Vcard.from_vcard(v) }.should raise_error Virginity::InvalidVcard
  end



  specify "but not vCalendars" do
    v = <<end_vcal
BEGIN:VCALENDAR
BEGIN:VTODO
SUMMARY:Je ne sais pas
CLASS:PUBLIC
PRIORITY:2
STATUS:NEEDS ACTION
END:VTODO
VERSION:3.0
N:;;;;
FN:
END:VCALENDAR
end_vcal
    lambda { Vcard.from_vcard(v) }.should raise_error Virginity::InvalidVcard
  end
end



describe "breaking vCards" do
  specify "adding a field could break a vcard" do
    v = Vcard.new
    begin
      v.add('tel') do |t|
        t.address = "bulls on parade" # this raises an error since a telephone does not have an address
      end
    rescue => e
      #puts e
      nil
    end
    lambda { Vcard.from_vcard(v.to_s) }.should_not raise_error StandardError
  end

  specify "adding a stupid field could break a vcard" do
    v = Vcard.new
    begin
      v.add_field('LALA') do |t|
        t.address = "bulls on parade" # this raises an error since a lala does not have an address
      end
    rescue => e
      #puts e
      nil
    end
    lambda { Vcard.from_vcard(v.to_s) }.should_not raise_error StandardError
  end
end

describe "reading some faulty vcards" do
  specify "should be able to figure out that WORK means TYPE=WORK" do
    @vcf = <<end_vcard
BEGIN:VCARD
VERSION:3.0
N:Albert;Philippe;;;
TEL;WORK:123
END:VCARD
end_vcard

    begin
      Vcard.from_vcard(@vcf)
    rescue => error
      puts error.original.backtrace
    end

    lambda { Vcard.from_vcard(@vcf) }.should_not raise_error
    v = Vcard.from_vcard(@vcf)
    v.telephones.first.types.should include('WORK')
  end
end
