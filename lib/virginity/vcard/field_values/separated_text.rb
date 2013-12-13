require 'reactive_array'
require 'digest/sha1'

module Virginity
  module FieldValues

    module SeparatedText


      class TextList < SerializingArray
        def initialize(field)
          @field = field # a reference to the original Field
          super(EncodingDecoding::decode_text_list(@field.raw_value))
          save_sha1!
        end

        def sha1
          Digest::SHA1.hexdigest(@field.raw_value)
        end

        def save_sha1!
          @sha1 = sha1
        end

        def needs_refresh?
          @sha1 != sha1
        end

        def rewrite!
          @array.delete_if {|v| v.empty? }
          @field.raw_value = EncodingDecoding::encode_text_list(@array)
          save_sha1!
        end
      end


      def values
        if (@textlist.needs_refresh? rescue true)
          @textlist = TextList.new(self)
        else
          @textlist
        end
      end

      def values=(a)
        values.replace(a)
      end

      def reencode!
        values.rewrite!
      end

      def subset_of?(other)
        values.all? { |v| other.values.include? v }
      end
    end

  end
end
