# -*- encoding: utf-8 -*-
require "#{File.dirname(__FILE__)}/spec_helper"

describe "Virginity::Field" do

  specify "params interface without any params" do
    x = Field.from_line("FOO:bar")
    x.params.should == []
    x.params.should be_empty
  end

  specify "params interface with a param" do
    x = Field.from_line("TEL;TYPE=baz:bar")
    x.params.should_not == []
    x.params.should_not be_empty
    types = x.params.select {|p| p.key == 'TYPE' }.map {|p| p.value}
    types.should_not be_nil
    types.should include "baz"
    types.should == ["baz"]
  end

  specify "changing the location" do
    x = Tel.at_random
    x.params.should == []
    x.params.should be_empty
    x.location = "WORK"
    x.params.size.should == 1
    x.location = "HOME"
    x.location.should == "HOME"
    x.params.size.should == 1
  end

  specify "preferred?" do
    x = Tel.at_random
    x.preferred?.should == false
    x.preferred = true
    x.params.size.should == 1
    x.preferred?.should == true
    x.preferred = false
    x.params.size.should == 0
    x.preferred?.should == false
  end

  specify "changing the value" do
    x = Field.from_line("TEL;TYPE=baz:bar")
    x.text.should == "bar"
    x.text = "555"
    x.raw_value.should == "555"
    x.text.should == "555"
    x.to_s.should include "555"

    x.text = "5\n55"
    x.raw_value.should == "5\\n55"
    x.text.should == "5\n55"
    x.to_s.should include "5\\n55"
    x.params.map { |p| p.to_s }.should include "TYPE=baz"

    x.text = "5,55"
    x.raw_value.should == "5\\,55"
    x.text.should == "5,55"
    x.params.map { |p| p.to_s }.should include "TYPE=baz"
  end


  specify "merging of fields" do
    x = Field.from_line("TEL;TYPE=bar:bar")
    y = Field.from_line("TEL;TYPE=baz:bar")
    Field.merger(x, x).to_s.should == x.to_s
    Field.merger(x, y).to_s.should_not == x.to_s
    Field.merger(x, y).should be_instance_of Virginity::Field::Tel
  end

  specify "conversion of X-ICQ to IMPP" do
    x = Field.from_line("X-ICQ:12345")
    impp = x.to_impp
    impp.should be_instance_of Virginity::Field::Impp
    impp.text.should == "icq:12345"
  end

  specify "date handling" do
    x = Field.from_line("BDAY:1979-05-04")
    x.date.should == Date.civil(1979,5,4)
    x.date = Date.civil(1982,1,1)
    x.raw_value.should == "1982-01-01"
  end

  # https://soocial.lighthouseapp.com/projects/10687-soocial/tickets/1211
  specify "label change" do
    x = Field.from_line("TEL;TYPE=FAX:007")
    x.type = "CELL"
    x.params.first.value.should == "CELL"
    x.params.size.should == 1
    x.raw_value.should == "007"
    x.type = "CELL FAX"
    x.params.size.should == 2
    x.raw_value.should == "007"
  end

  # https://soocial.lighthouseapp.com/projects/10687-soocial/tickets/1211
  specify "location change" do
    x = Field.from_line("TEL;TYPE=FAX:007")
    x.location = "CELL"
    x.params.size.should == 2
    x.raw_value.should == "007"
  end

  specify "type change like the gmail engine" do
    x = Field.from_line("TEL;TYPE=FAX:007")
    x.types.concat(["ASSISTANT", "CAR"])
    x.params.size.should == 3
    x.raw_value.should == "007"
  end

  specify "removing a TYPE" do
    x = Field.from_line("TEL;TYPE=foo,bar:bar")
    x.remove_type("foo")
    x.params.join.should_not include "foo"
  end

  specify "removing a TYPE from a vcard" do
    v = Vcard.new
    v << Field.from_line("TEL;TYPE=foo,bar:zom")
    v.fields.each do |f|
      f.remove_type("bar") if f.respond_to? :remove_type
    end
    (v/"TEL").first.remove_type("foo")
    v.to_s.should_not include "bar"
    v.to_s.should_not include "foo"
  end

end


describe "Reencoding" do
  specify "normal text fields" do
    x = Field.from_line("TEL;TYPE=baz:ba,r")
    x.text.should == "ba,r"
    x.raw_value.should_not include "\\"
    x.reencode!
    x.text.should == "ba,r"
    x.raw_value.should include "\\"
  end

  specify "structured fields" do
    x = Field.from_line("ADR;TYPE=WORK:;;5, boulevard Eiffel;LONGVIC;;21600;")
    x.street.should == "5, boulevard Eiffel"
    x.raw_value.should_not include "\\"
    x.reencode!
    x.street.should == "5\, boulevard Eiffel"
    x.raw_value.should include "\\"
  end

  specify "separated fields" do
    x = Field.from_line("NICKNAME:com;ma,comm;a,")
    x.raw_value.should_not include "\\"
    x.reencode!
    x.values.should == %w(com;ma comm;a)
    x.raw_value.should include "\\"
  end
end


describe "Field comparison" do

  specify "fields with different names" do
    f = Field.from_line("TEL;TYPE=foo,bar:zom")
    g = Field.from_line("EMAIL;TYPE=foo,bar:zom")
    [f, g].sort.first.should == g
  end

  specify "fields with different params" do
    f = Field.from_line("TEL;TYPE=PREF,bar:zom").clean!
    g = Field.from_line("TEL;TYPE=foo,bar:zom").clean!
    [f, g].sort.first.should == f
    f = Field.from_line("TEL;TYPE=PREF,bar:zom").clean!
    g = Field.from_line("TEL;TYPE=foo,PREF:zom").clean!
    [f, g].sort.first.should == f
  end

  specify "fields with different params" do
    f = Field.from_line("TEL;TYPE=PREF,bar:aom").clean!
    g = Field.from_line("TEL;TYPE=bar,PREF:zom").clean!
    [f, g].sort.first.should == f
  end



  specify "BEGIN and END are special!" do
    s = <<end_vcard
BEGIN:VCARD
VERSION:3.0
N:All1;Fields Filled.;;Title1;Suffix1
NICKNAME:Nick1
TITLE:Jobtitel
EMAIL;TYPE=INTERNET,PREF,WORK:email3@mail.com
EMAIL;TYPE=INTERNET,WORK:email1@mail.com
EMAIL;TYPE=INTERNET,WORK:email2@mail.com
TEL;TYPE=OTHER,PREF:carr1111
TEL;TYPE=FAX,WORK:otherfax111
TEL;TYPE=WORK:business111
TEL;TYPE=PAGER:pager111
TEL;TYPE=HOME:home2111
TEL;TYPE=FAX,HOME:homefax111
TEL;TYPE=OTHER:other111
TEL;TYPE=OTHER:radio111
TEL;TYPE=OTHER:assistant111
TEL;TYPE=CELL:mobiel111
TEL;TYPE=OTHER:telex111
TEL;TYPE=OTHER:callback111
TEL;TYPE=WORK:bussiness2111
TEL;TYPE=OTHER:primary111
TEL;TYPE=HOME:home111
TEL;TYPE=WORK:company111
ADR;TYPE=PREF,WORK;X-FORMAT=nl:;;address1;businesscity;state;1111;United States of America
ADR;TYPE=WORK;X-FORMAT=nl:;;prefotherstreet1;othercity;ostate;222OO;United States of America
ADR;TYPE=WORK;X-FORMAT=nl:;;homestreet1;homecity;hstate;111hh;United States of America
URL;TYPE=HOMEPAGE,PREF:http\://webpage.com
BDAY;VALUE=date:2009-08-01
CATEGORIES:Outlook
PRIORITY;X-SOOCIAL-OUTLOOK=Importance:1
X-PROFESSION:profesion
X-COMPANY;X-SOOCIAL-OUTLOOK=Department:dept1
X-COMPANY;X-SOOCIAL-OUTLOOK=OfficeLocation:office1
X-SPOUSE:Spouse1
X-OUTLOOK-GENDER:0
X-ASSISTANT:Assistanname
X-PROFESSION:proff1
X-COMPANY;X-SOOCIAL-OUTLOOK=CompanyName:comany1
X-COMPANY;X-SOOCIAL-OUTLOOK=Department:departement1
X-ASSISTANT:Assistan1
FN:Fields Filled. All1
END:VCARD
end_vcard
    v = Vcard.from_vcard(s)
    lambda { Vcard.from_vcard(v.fields.sort.join("\n")) }.should_not raise_error
    w = Vcard.from_vcard(v.fields.sort.join("\n"))
    # every field that is in v should also be in w
    v.fields.each do |vf|
      w.fields.detect {|wf| wf.to_s == vf.to_s }.should_not be_nil
    end

    require 'benchmark'
    s = <<end_vcard
BEGIN:VCARD
VERSION:3.0
N:All1;Fields Filled.;;Title1;Suffix1
NICKNAME:Nick1
EMAIL;TYPE=INTERNET,PREF,WORK:email3@mail.com
EMAIL;TYPE=INTERNET,WORK:email1@mail.com
EMAIL;TYPE=INTERNET,WORK:email2@mail.com
TEL;TYPE=OTHER,PREF:carr1111
TEL;TYPE=FAX,WORK:otherfax111
TEL;TYPE=WORK:business111
TEL;TYPE=PAGER:pager111
ADR;TYPE=PREF,WORK;X-FORMAT=nl:;;address1;businesscity;state;1111;United States of America
ADR;TYPE=WORK;X-FORMAT=nl:;;prefotherstreet1;othercity;ostate;222OO;United States of America
ADR;TYPE=WORK;X-FORMAT=nl:;;homestreet1;homecity;hstate;111hh;United States of America
URL;TYPE=HOMEPAGE,PREF:http\://webpage.com
BDAY;VALUE=date:2009-08-01
CATEGORIES:Outlook
FN:Fields Filled. All1
END:VCARD
end_vcard
    v = Vcard.from_vcard(s)
#     puts
#     Benchmark.bm("unsorted".size) do |bm|
#       bm.report("unsorted") { 1000.times { v.fields.sort } }
#       v.fields.sort!
#       bm.report("sorted") { 1000.times { v.fields.sort } }
#     end
  end

  specify "address subsets" do
    f = Field.from_line("ADR;TYPE=HOME:;;Bickerson Street 4;Dudley Town;;6215 AX;NeverNeverland")
    g = Field.from_line("ADR;TYPE=HOME:;;Bickerson Street 4;Dudley Town;;;")
    g.should be_subset_of(f)
    f.should_not be_subset_of(g)
  end

  specify "address.empty?" do
    f = Field.from_line("ADR;TYPE=HOME:;;Bickerson Street 4;Dudley Town;;6215 AX;NeverNeverland")
    g = Field.from_line("ADR;TYPE=HOME:;;;;;;")
    g.should be_empty
    f.should_not be_empty
  end

end

describe "utf-8 encoded value" do
  specify 'Fred' do
    fred = "Frédéric"
    f = Field.from_line("FN:"+fred)
    f.text.encoding.should == Encoding::UTF_8 if "Ruby1.9".respond_to? :encoding
    f.text.should == fred

    if "Ruby1.9".respond_to? :encoding
      lambda { Field.from_line ("FN:"+fred).encode(Encoding::UTF_16LE) }.should raise_error Virginity::InvalidEncoding
    end
  end

  specify "Eugene" do
    eugene = "Евгений Пименов"
    f = Field.from_line("FN:"+eugene)
    f.text.encoding.should == Encoding::UTF_8 if "Ruby1.9".respond_to? :encoding
    f.text.should == eugene
  end
end
