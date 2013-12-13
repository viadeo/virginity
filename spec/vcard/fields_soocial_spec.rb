require 'spec_helper'

describe Virginity::Vcard::XSoocialCustom do
  it { should be_registered_for('X-SOOCIAL-CUSTOM') }

  when_parsing "X-SOOCIAL-CUSTOM;NAME=key:value" do
    its(:key_name) { should == 'key' }
    its(:text) { should == 'value' }
    its(:value) { should == 'value' }

    its(:to_s) { should == 'X-SOOCIAL-CUSTOM:key;value' }
  end

  when_parsing "X-SOOCIAL-CUSTOM:key;value" do
    its(:key_name) { should == 'key' }
    its(:text) { should == 'value' }
    its(:value) { should == 'value' }
  end

  context 'when saving' do
    it 'prefers new format' do
      f = Virginity::Vcard::XSoocialCustom.new('X-SOOCIAL-CUSTOM')
      f.key_name = 'key'
      f.value = 'value'
      f.to_s.should == 'X-SOOCIAL-CUSTOM:key;value'
    end
  end
end
