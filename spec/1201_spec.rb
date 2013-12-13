require "#{File.dirname(__FILE__)}/spec_helper"

describe "virginity crashes on vcards coming from Synthesis iPhone #1201" do
  it "it should not crash on the first example" do
s = <<end_vcard
BEGIN:VCARD
VERSION:2.1
REV:20090330T124708Z
N:Dropbox;Highrise;;;
FN:Highrise Dropbox
ORG:Highrise;
TEL:
EMAIL;WORK;INTERNET;X-Synthesis-Ref0;ENCODING=QUOTED-PRINTABLE:dro=
pbox@22380245.soocial.highrisehq.com
URL:
ADR:;;;;;;
BDAY:
END:VCARD
end_vcard
    s.force_encoding(Encoding::UTF_8) if "Ruby1.9".respond_to? :encoding
    lambda { Virginity::Vcard.from_vcard(s) }.should_not raise_error
  end

  it "it should not crash on the second example" do
s = <<end_vcard
BEGIN:VCARD
VERSION:2.1
REV:20090401T095552Z
N:Hardy;Lachlan;;;
FN:Lachlan Hardy
TEL:
URL:
ADR:;;;;;;
BDAY:
NOTE;ENCODING=QUOTED-PRINTABLE:Guys from down under, he's pretty c=
ool fellow.=0D=0A=
Guys from down under, he's pretty cool fellow.=0D=0A=
Guys from down under, he's pretty cool fellow.
END:VCARD
end_vcard
    s.force_encoding(Encoding::UTF_8) if "Ruby1.9".respond_to? :encoding
    lambda { Virginity::Vcard.from_vcard(s) }.should_not raise_error
  end

end
