require 'spec_helper'

describe Virginity::Vcard::Gender do
  it { should be_registered_for('GENDER') }

  shared_examples_for "a male" do
    it { should be_male }
    it { should_not be_female }
    it { should_not be_other }
    it { should_not be_none }
    it { should_not be_unknown }
  end

  shared_examples_for "a female" do
    it { should_not be_male }
    it { should be_female }
    it { should_not be_other }
    it { should_not be_none }
    it { should_not be_unknown }
  end

  when_parsing "GENDER:M" do
    it_should_behave_like "a male"
    its(:identity) { should be_empty }
  end

  when_parsing "GENDER:F" do
    it_should_behave_like "a female"
    its(:identity) { should be_empty }
  end

  when_parsing "GENDER:M;Fellow" do
    it_should_behave_like "a male"
    its(:identity) { should == 'Fellow' }
  end

  when_parsing "GENDER:F;grrrl" do
    it_should_behave_like "a female"
    its(:identity) { should == 'grrrl' }
  end

  when_parsing "GENDER:O;intersex" do
    it { should be_other }
    its(:identity) { should == 'intersex' }
  end

  when_parsing "GENDER:;it's complicated" do
    it { should be_neither }
    its(:identity) { should == "it's complicated" }
  end

  when_parsing "GENDER:N;A ship" do
    it { should be_none }
    its(:identity) { should == 'A ship' }
  end

  context 'when saving' do
    let(:f) { Virginity::Vcard::Gender.new('GENDER') }
    it 'leaves identity out if not present' do
      f.male = true
      f.to_s.should == 'GENDER:M'
    end

    it 'does not lose identity if present' do
      f.male = true
      f.identity = 'The dude'
      f.to_s.should == 'GENDER:M;The dude'
    end

    it 'handles blanks' do
      f.sex = ""
      f.to_s.should == 'GENDER:'
    end
  end
end
