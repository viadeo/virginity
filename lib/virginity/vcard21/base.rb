module Virginity
  module Vcard21
    # FIXME: X-FUNAMBOL-INSTANTMESSENGER shouldnt be here! it's just to get funambol's thunderbird client to work
    KNOWNTYPES = %w(DOM INTL POSTAL PARCEL HOME WORK PREF VOICE FAX MSG CELL PAGER BBS MODEM CAR ISDN VIDEO AOL APPLELINK ATTMAIL CIS EWORLD INTERNET IBMMAIL MCIMAIL POWERSHARE PRODIGY TLX X400 GIF CGM WMF BMP MET PMB DIB PICT TIFF PDF PS JPEG QTIME MPEG MPEG2 AVI WAVE AIFF PCM X509 PGP) +
      %w(X-FUNAMBOL-INSTANTMESSENGER INTERNET) # additions to work with common errors. This means that we now cannot have a param with the name INTERNET in vcard2.1

    ENCODING =  /^ENCODING$/i
    BASE64 = /^BASE64$/i
    QUOTED_PRINTABLE = /^quoted-printable$/i
    SEVEN_BIT = /^7bit$/i
    EIGHT_BIT = /^8bit$/i

    def self.base64_param?(param)
      param.key =~ ENCODING and param.value =~ BASE64
    end

    def self.qp_param?(param)
      param.key =~ ENCODING and param.value =~ QUOTED_PRINTABLE
    end

    def self.seven_bit?(param)
      param.key =~ ENCODING and param.value =~ SEVEN_BIT
    end

    def self.eight_bit?(param)
      param.key =~ ENCODING and param.value =~ EIGHT_BIT
    end

  end
end
