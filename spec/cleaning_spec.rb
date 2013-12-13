# -*- encoding: utf-8 -*-
require "spec_helper"

describe "cleaning vcards" do
  include Virginity::Encodings

  specify "duplicate_value_fields" do
    original = Vcard.new <<end_vcard
BEGIN:VCARD
VERSION:3.0
N;CHARSET=UTF-8:Arrington;Michael;;;
FN;CHARSET=UTF-8:Michael Arrington
TEL;TYPE=WORK:123
TEL;TYPE=WORK:123
TEL;TYPE=HOME:123
END:VCARD
end_vcard
    original.clean_same_value_fields!
    (original/"TEL").size.should == 1
    tel = (original/"TEL").first
    tel.name.should == "TEL"
    tel.raw_value.should == "123"
    tel.params.size.should == 2
    tel.params.sort.first.to_s.should == "TYPE=HOME"
    tel.params.sort.last.to_s.should == "TYPE=WORK"
  end

  specify "assimilate fields" do
    sandra = <<end_vcard
BEGIN:VCARD
VERSION:3.0
N:van de Broek;Sanne
FN:Sanne van de Broek
END:VCARD
end_vcard
    s = <<end_vcard
BEGIN:VCARD
N:van de Broek;Sanne
TEL;TYPE=CELL:1616161616
X-IRMC-LUID:0002000003A5
VERSION:3.0
FN:Sanne van de Broek
END:VCARD
end_vcard
    s1 = Vcard.new(sandra)
    s1.assimilate_fields_from!(Vcard.new(s))
    s1.telephones.size.should == 1
    s1.assimilate_fields_from!(Vcard.new(s))
    s1.telephones.size.should == 1
    s1.assimilate_fields_from!(Vcard.new(s))
    s1.telephones.size.should == 1
  end

  specify "FN-generation" do
    apple = Vcard.new(File.read("#{VCARDS_ROOT}/apple.vcf"))
    (apple/"FN").should be_empty
    apple.name.formatted.should == "Apple Computer Benelux BV"
    (apple/"FN").should_not be_empty
  end

  specify "Norbert's example" do
    # ticket https://soocial.lighthouseapp.com/projects/10687/tickets/1073-improve-clean-methods-for-duplicate-fields
    v = Vcard.new
    v << "TEL;TYPE=HOME:123"
    v << "TEL;TYPE=PREF:123"
    v.clean!
    v.telephones.size.should == 1
    v.telephones.first.params.size.should == 2
    joined = v.telephones.first.params.join("")
    joined.should include "HOME"
    joined.should include "PREF"
  end

  specify "Remove ; from ORG field for Blackberry" do
    # ticket https://soocial.lighthouseapp.com/projects/10687/tickets/1110-remove-from-org-field-for-blackberry
    v = Vcard.new
    v << "ORG:Blah corp.;;"
    v.clean!
    v.organisations.size.should == 1
    #puts v.organisations.first.to_s
    v.organisations.first.to_s.should_not include ";"
  end

  specify "X-Synthesis-Ref[number]" do
    # https://soocial.lighthouseapp.com/projects/10687/tickets/1200-x-synthesis-ref-params
    v = Vcard.new
    v << "TEL;X-Synthesis-Ref1:1"
    v << "TEL;X-Synthesis-Ref23:2"
    v << "TEL;X-Synthesis-Ref456:3"
    v << "TEL;X-Synthesis-Ref7890:4"
    v.telephones.size.should == 4
    v.clean!
    v.telephones.size.should == 4
    v.telephones.each do |t|
      t.params.size.should == 0
    end
  end

  specify "X-Synthesis-Ref[number]" do
    v = File.read("#{VCARDS_ROOT}/faulty/cecilia.vcf")
    lambda{Vcard.from_vcard21(v) }.should_not raise_error
  end

  specify "whitespace after field contents" do
    v = Vcard.new
    v << "TEL:3 "
    v << "TEL:4\n"
    v.telephones.first.number.should include(" ")
    v.clean!
    v.telephones.last.number.should_not include("\n")
    v.telephones.first.number.should_not include(" ")
  end

  # after unpacking there should be one nickname value per NICKNAME
  # the order should not change.
  specify "nickname unpacking" do
    nicked = Vcard.new <<-end_vcard
BEGIN:VCARD
VERSION:3.0
N;CHARSET=UTF-8:Arrington;Michael;;;
NICKNAME:Mike,Mikey,Mich
END:VCARD
end_vcard
    original_nicknames = nicked.name.nicknames
    nicked.unpack_nicknames!
    (nicked/"NICKNAME").size.should == 3
    mike = (nicked/"NICKNAME").first
    mike.values.first.should == "Mike"
    mikey = (nicked/"NICKNAME")[1]
    mikey.values.first.should == "Mikey"
    mich = (nicked/"NICKNAME")[2]
    mich.values.first.should == "Mich"
    nicked.name.nicknames.should == original_nicknames
  end

  specify "nickname unpacking should keep the order" do
    nicked = Vcard.new <<-end_vcard
BEGIN:VCARD
NICKNAME:Arr,M.A.
VERSION:3.0
N;CHARSET=UTF-8:Arrington;Michael;;;
NICKNAME:Mike,Mikey,Mich
END:VCARD
end_vcard
    original_nicknames = nicked.name.nicknames
    nicked.unpack_nicknames!
    (nicked/"NICKNAME").size.should == 5
    (nicked/"NICKNAME").map {|n| n.values.first }.should == %w(Arr M.A. Mike Mikey Mich)
    (nicked/"NICKNAME").map {|n| n.values.first }.each do |nickname|
      nickname.should_not be_empty
    end
  end

  specify "nickname unpacking should keep the order" do
    nicked = Vcard.new <<-end_vcard
BEGIN:VCARD
NICKNAME:Arr
VERSION:3.0
N;CHARSET=UTF-8:Arrington;Michael;;;
NICKNAME:Mike
END:VCARD
end_vcard
    original_nicknames = nicked.name.nicknames
    nicked.unpack_nicknames!
    (nicked/"NICKNAME").size.should == 2
    (nicked/"NICKNAME").map {|n| n.values.first }.should == %w(Arr Mike)
    (nicked/"NICKNAME").map {|n| n.values.first }.each do |nickname|
      nickname.should_not be_empty
    end
  end

  specify "categories should have no trailing or leading spaces" do
    x = Vcard.new
    x.add_category "  spaced  "
    x.add_category " to to to"
    x.clean!
    y = Vcard.new(x.to_s)
    y.category_values.each do |c|
      c.should == c.strip
    end
    y.add_category " spaced "
    y.clean!
    z = Vcard.new(y.to_s)
    z.category_values.each do |c|
      c.should == c.strip
    end
  end


  specify "QP categories should be reencoded" do
    s = <<-end_vcard
BEGIN:VCARD
VERSION:3.0
N:1643 0.5ct6;;;;
FN:1643 0.5ct6
TEL;type=CELL;type=pref:0202225225
NOTE;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:=0A=0A=0A=0A=0A=0A=0A=0A
CATEGORIES;CHARSET=UTF-8;ENCODING=QUOTED-PRINTABLE:Amo=20Amazon=C3=ADa
END:VCARD
end_vcard
    v = Vcard.new(s)
    v.clean!
    v.to_s.should_not include "Amo=20Amazon=C3=ADa"
    v.to_s.should include "Amo Amazonía"
  end

  specify "categories should be unique and sorted" do
    s = <<-end_vcard
BEGIN:VCARD
VERSION:3.0
N:1643 0.5ct6;;;;
FN:1643 0.5ct6
TEL;type=CELL;type=pref:0202225225
CATEGORIES:foo,foo,bar
END:VCARD
end_vcard
    v = Vcard.new(s)
    v.clean!
    (v/"CATEGORIES").first.values.should == %w(bar foo)
    v.to_s.should include "CATEGORIES:bar,foo"
  end

  specify "categories should be unique and sorted" do
    s = <<-end_vcard
BEGIN:VCARD
VERSION:3.0
N:1643 0.5ct6;;;;
FN:1643 0.5ct6
TEL;type=CELL;type=pref:0202225225
CATEGORIES:foo,foo,bar
CATEGORIES:baz
END:VCARD
end_vcard
    v = Vcard.new(s)
    v.clean!
    (v/"CATEGORIES").first.values.should == %w(bar baz foo)
    v.to_s.should include "CATEGORIES:bar,baz,foo"
  end

  specify "these notes should disappear since they are empty" do
    # #1423 virginity's empty field clean should be smarter
    s = <<end_vcard
BEGIN:VCARD
N:Smit;Jan;;;
BDAY:19710508
TEL;TYPE=FAX,WORK:
CATEGORIES:Personal
FN:Jan Smit
EMAIL;TYPE=INTERNET:jan_smit@soocial.com
TEL;TYPE=HOME,VOICE:(414) 647-498187
PRIORITY:1
TEL;TYPE=CELL:(117) 124-039465
CLASS:PUBLIC
VERSION:3.0
END:VCARD
end_vcard
    v = Vcard.new(s)
    v << "NOTE:\n\n"
    v << "NOTE:\n\n\n\n"
    v << "NOTE:\n\n\n"
    (v/"NOTE").should_not be_empty
    (v/"NOTE").size.should == 3
    v.clean!
    (v/"NOTE").should be_empty
  end

  specify "Base64 params" do
    s = <<-end_vcard
BEGIN:VCARD
N:Smit;Jan;;;
PHOTO;ENCODING=BASE64:efnnqnf
VERSION:3.0
END:VCARD
end_vcard
    v = Vcard.new(s)
    (v/"PHOTO").first.params.first.value.should == "BASE64"
    v.clean!
    (v/"PHOTO").first.params.first.value.should == "b"
  end

  specify "Multiple Versions" do
    s = <<-end_vcard
BEGIN:VCARD
N:Smit;Jan;;;
VERSION:3.0
VERSION:3.0
VERSION:3.0
END:VCARD
end_vcard
    v = Vcard.new(s)
    (v/"VERSION").size.should == 3
    v.clean!
    (v/"VERSION").size.should == 1
  end

  specify "Multiple Versions" do
    s = <<-end_vcard
BEGIN:VCARD
N:Smit;Jan;;;
VERSION:3.0
X-IRMC-LUID:3564687
X-ABUID:3
END:VCARD
end_vcard
    v = Vcard.new(s)
    (v/"X-ABUID").should_not be_empty
    (v/"X-IRMC-LUID").should_not be_empty
    v.clean!
    (v/"X-ABUID").should be_empty
    (v/"X-IRMC-LUID").should be_empty
  end

  specify "address is subset of another address" do
    s = <<-end_vcard
BEGIN:VCARD
N:Smit;Jan;;;
VERSION:3.0
ADR;TYPE=HOME:;;Bickerson Street 4;Dudley Town;;6215 AX;NeverNeverland
ADR;TYPE=HOME:;;Bickerson Street 4;Dudley Town;;;
END:VCARD
end_vcard
    v = Vcard.new(s)
    (v/"ADR").size.should == 2
    v.clean!
    (v/"ADR").size.should == 1
    (v/"ADR").first.postal_code.should_not be_empty
  end

  specify "address is subset of another address" do
    s = <<-end_vcard
BEGIN:VCARD
N:Smit;Jan;;;
VERSION:3.0
ADR;TYPE=HOME:;;Bickerson Street 4;Dudley Town;;6215 AX;NeverNeverland
ADR;TYPE=HOME:;;Bickerson Street 4;Dudley Town;;;
PHOTO:x
PHOTO:y
PHOTO:z
LOGO:a
LOGO:b
LOGO:c
END:VCARD
end_vcard
      v = Vcard.new(s)
      v.photos.size.should == 3
      v.logos.size.should == 3
      v.remove_extra_photos!
      v.remove_extra_logos!
      v.photos.size.should == 1
      v.logos.size.should == 1
      v.logos.first.raw_value.should == "a"
      v.photos.first.raw_value.should == "x"
  end
end

describe "date cleaning" do
  specify "valid date without dashes" do
    s = <<-end_vcard
BEGIN:VCARD
N:van Boven;Gerrie;;;
BDAY:1986-04-29
BDAY:19860429
END:VCARD
end_vcard
    v = Vcard.new(s)
    v.birthdays.size.should == 2
    v.clean_dates!
    v.clean_same_value_fields!
    v.birthdays.size.should == 1
    v.birthdays.first.date.to_s.should == '1986-04-29'
    v.to_s.should include('1986-04-29')
  end
end

describe "address cleaning" do
  specify "address is subset of another address" do
    s = <<-end_vcard
BEGIN:VCARD
N:van Boven;Gerrie;;;
BDAY:1986-04-29
BDAY:friday 13th
END:VCARD
end_vcard
    v = Vcard.new(s)
    v.birthdays.size.should == 2
    v.clean_dates!
    v.clean_same_value_fields!
    v.birthdays.size.should == 2
    v.birthdays.first.date.to_s.should == '1986-04-29'
    v.to_s.should include('1986-04-29')
  end

  specify "address field with less than 7 parts" do
    s = <<-end_vcard
BEGIN:VCARD
VERSION:3.0
N:;Bart;;;
ADR:hier;;
FN:Bart
END:VCARD
end_vcard
    v = Vcard.new(s)
    v.clean!
    v.to_s.should include('ADR:hier;;;;;;')
  end
end


describe "multiple N-fields" do
  specify "duplicate N fields" do
    s = <<-end_vcard
BEGIN:VCARD
VERSION:3.0
N:;Bart;;;
N:;Bart;;;
END:VCARD
end_vcard
    v = Vcard.new(s)
    v.clean!
    v.lines_with_name('N').size.should == 1
  end

  specify "pick the longest" do
    s = <<-end_vcard
BEGIN:VCARD
VERSION:3.0
N:;Bart;;;
N:Jansen;Bart;;;
END:VCARD
end_vcard
    v = Vcard.new(s)
    v.clean!
    v.lines_with_name('N').size.should == 1
    v.name.family.should == "Jansen"
  end

    specify "pick the longest" do
    s = <<-end_vcard
BEGIN:VCARD
VERSION:3.0
N:Jansen;Bart;;;
N:;Bart;;;
N:;Jan;;;
END:VCARD
end_vcard
    v = Vcard.new(s)
    v.clean!
    v.lines_with_name('N').size.should == 1
    v.name.family.should == "Jansen"
  end


end
