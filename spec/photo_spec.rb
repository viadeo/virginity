#!/usr/bin/env ruby
require "#{File.dirname(__FILE__)}/spec_helper"

describe "Fix broken photos" do
  before do
    @vcards = Dir.glob("#{VCARDS_ROOT}/broken_photos/*.vcf").map { |vcf| File.read vcf }
    @vcards.should_not be_empty
  end

  specify "should be able to load the vcards" do
    @vcards.each do |vcf|
      lambda { Vcard.from_vcard(vcf) }.should_not raise_error
    end
  end

  specify "should be able to load the vcards" do
#     File.open("aap.html", "w") do |f|
      @vcards.each do |vcf|
        john = Vcard.from_vcard(vcf)
        (john/'PHOTO').each do |photo|
          photo.raw_value.include?(" ").should == false
#           f.puts "<img src=\"data:image/jpeg;base64,#{photo.value}\" />\n"
        end
      end
#     end
  end
end
