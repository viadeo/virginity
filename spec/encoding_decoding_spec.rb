require "#{File.dirname(__FILE__)}/spec_helper"


describe "Virginity::Rfc2425" do
  specify "encode text" do
    EncodingDecoding::encode_text("5,55").should == "5\\,55"
  end

  specify "decode text" do
    EncodingDecoding::decode_text("5,55").should == "5,55"
    "5\\,55".should_not == "5,55"
    EncodingDecoding::decode_text("5\\,55").should == "5,55"
  end

  specify "encode_text_list" do
    EncodingDecoding::encode_text_list(["5", "55"]).should == "5,55"
    EncodingDecoding::encode_text_list(["5,55"]).should == "5\\,55"
  end

  specify "decode_text_list" do
    EncodingDecoding::decode_text_list("5,55").should == ["5", "55"]
    EncodingDecoding::decode_text_list("5\\,55").should == ["5,55"]
    EncodingDecoding::decode_text_list("5;55").should == ["5;55"]
  end

  specify "text with newlines" do
    lambda { EncodingDecoding::encode_text_list([";;191 West Nationwide Blvd.\r\nSuite 500;Columbus;OH;43215;US"])}.should_not raise_error
  end

  specify "text with chars that would be illegal in a param" do
    lambda { EncodingDecoding::encode_text_list([";;191 West Nationwide Blvd.\r\n" << 5<< "Suite 500;Columbus;OH;43215;US"]) }.should_not raise_error
  end
end


describe "Quoted Printable" do

  specify "encoding " do
    text = "For example, in the Quoted-Printable encoding the multiple lines of formatted text are separated with a\r\nQuoted-Printable CRLF sequence of \"=0D\" followed by \"=0A\" followed by a Quoted-Printable softline break sequence\n of \"=\". Quoted-Printable lines of text must also be limited to less than 76 characters. The 76 characters\ndoes not include the CRLF (RFC 822) line break sequence. For example a multiple line LABEL property\n value of:"
    (1..80).each do
      s = EncodingDecoding::encode_quoted_printable(text)
      # puts "\n", s.inspect
      s.should_not include " "
      text.should == EncodingDecoding::decode_quoted_printable(s)
      s.split("\n").each { |x| x.size.should <= 76 }
      text = " " + text # prepend with spaces to check the folding method.
    end
  end


end
