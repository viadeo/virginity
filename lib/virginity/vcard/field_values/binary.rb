module Virginity
  module FieldValues

    module Binary
      def binary
        Base64.decode64(@value)
      end

      def binary=(s)
        @params.delete_if { |p| p.key == "ENCODING" }
        @params << Param.new("ENCODING", "b")
        b64 = Base64.encode64(s)
        b64.delete!("\n") # can return nil... bah, but probably faster than #delete without an exclamation mark
        @value = b64
      end

      def sha1
        Digest::SHA1.hexdigest(@value)
      end
    end
  end
end
