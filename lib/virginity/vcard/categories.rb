require 'reactive_array'
require 'virginity/vcard/fields'

module Virginity

  # methods to handle ALL categories fields in a Vcard. These work around the
  # difficulties of working with multiple CATEGORIES-lines in a vCard by not
  # trying to preserve any ordering or grouping.
  module VcardCategories

    def category_values
      categories.map {|cat| cat.values.to_a }.flatten.uniq.sort
    end

    def add_category(c)
      @tags = nil
      self.push SeparatedField.new("CATEGORIES", EncodingDecoding::encode_text(c))
    end

    def remove_category(c)
      @tags = nil
      categories.each { |cat| cat.values.delete(c) }
    end

    def in_category?(c)
      categories.any? { |cat| cat.values.include?(c) }
    end


    class TagArray < SerializingArray
      def initialize(vcard)
        @vcard = vcard
        super(@vcard.category_values)
      end

      def rewrite!
        @vcard.categories.each {|cat| @vcard.delete_field cat }
        @array.each do |tag|
          @vcard.add_category tag
        end
      end
    end


    def tags
      @tags ||= TagArray.new(self)
    end

    def tags=(array_of_tags)
      tags.replace(array_of_tags)
    end

    def tag(tag)
      tags << tag
    end
  end
end
