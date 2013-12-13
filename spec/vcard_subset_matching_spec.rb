require "#{File.dirname(__FILE__)}/spec_helper"

describe "vCard subset matching" do

  JOHN = <<end_vcard
BEGIN:VCARD
VERSION:3.0
N:Smith;John;M.;Mr.;Esq.
TEL;TYPE=WORK,VOICE,MSG:+1 (919) 555-1234
TEL;TYPE=CELL:+1 (919) 554-6758
TEL;TYPE=WORK,FAX:+1 (919) 555-9876
ADR;TYPE=WORK,PARCEL,POSTAL,DOM:Suite 101;1 Central St.;Any Town;NC;27654
END:VCARD
end_vcard

  before do
    @john = Vcard.from_vcard(JOHN)
  end

  specify "one field missing" do
    x = @john.deep_copy
    x.fields.delete_if {|f| f.name == 'ADR' }
    x.should_not == @john
    x.should be_subset_of(@john)
  end

  specify "a part of his name missing" do
    x = @john.deep_copy
    x.name.given = ''
    x.should_not == @john
    x.should be_subset_of(@john)
  end

  specify "another part of his name missing" do
    x = @john.deep_copy
    x.name.family = ''
    x.name.prefix = ''
    x.should_not == @john
    x.should be_subset_of(@john)
  end

  specify "a part of the address missing" do
    x = @john.deep_copy
    x.should == @john
    x.addresses.first.street = ''
    x.should_not == @john
    x.should be_subset_of(@john)
  end

  specify "labels missing" do
    x = @john.deep_copy
    x.should == @john
    x.telephones.each do |tel|
      tel.params.clear
    end
    x.should_not == @john

    x.should be_subset_of(@john)
  end

end
