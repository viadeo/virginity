require "spec_helper"

describe "Categories" do

  specify "adding a category" do
    v = Vcard.new
    v.category_values.should_not include "phone"
    v.add_category "phone"
    v.category_values.should include "phone"
  end

  specify "removing a category" do
    v = Vcard.new
    v.category_values.should_not include "phone"
    v.add_category "phone"
    v.category_values.should include "phone"
    # or equivalent:
    v.in_category?("phone").should be_true
    v.remove_category "phone"
    v.category_values.should_not include "phone"
    # or equivalent:
    v.in_category?("phone").should be_false
  end

  specify "adding a category should not delete another category" do
    v = Vcard.new
    v.category_values.should_not include "phone"
    v.add_category "phone"
    v.category_values.should include "phone"
    v.tag "bar"
    v.category_values.should include "phone"
    v.category_values.should include "bar"
    v.tags.should include "phone"
    v.tags.should include "bar"
  end

  specify "adding a category should not delete another category" do
    v = Vcard.new
    v.category_values.should_not include "phone"
    v.add_category "phone"
    v.category_values.should include "phone"
    v.tag "bar"
    v.tags.reject! {|t| t == "phone" }
    v.category_values.should_not include "phone"
    v.tags.should include "bar"
    v.category_values.should include "bar"
  end

  specify "replacing categories using tags=" do
    v = Vcard.new
    v.category_values.should_not include "phone"
    v.add_category "phone"
    v.add_category "tapir"
    # or equivalent:
    v.tags = %w(monkey)
    v.in_category?("phone").should be_false
    v.in_category?("tapir").should be_false
    v.in_category?("monkey").should be_true
    v.tags.size.should == 1
  end

end
