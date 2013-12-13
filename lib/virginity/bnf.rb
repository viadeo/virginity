module Virginity

  module Rfc882
    # rfc822 has a slightly different definition of quoted string compared to rfc2425... it's better
    QTEXT = /[^\"\\\n]/ # <any CHAR excepting <"> "\" & CR, and including linear-white-space
    QUOTED_PAIR = /\\./
    QUOTED_STRING = /(\"((#{QTEXT}|#{QUOTED_PAIR})*)\")/
  end


  module Rfc2234 #:nodoc: # Augmented BNF for Syntax Specifications: ABNF
    CRLF = /\r\n/
    DIGIT = /\d/
    WSP = /\s/ # whitespace
  end

  module Rfc2425
  end

  # Contains regular expression strings for the EBNF of rfc 2425.
  module Bnf #:nodoc:
    include Rfc882
    include Rfc2234
    include Rfc2425
    # 1*(ALPHA / DIGIT / "-")
    # added underscore '_' because it's produced by Notes - X-LOTUS-CHILD_UID
    # added a slash '/' so that it will match lines like: "X-messaging/xmpp-All:someone@gmail.com"
    # added a space ' ' so that it will match lines like: "X-GOOGLE TALK;TYPE=WORK:janklaassen"
    NAME    = '[a-zA-Z0-9][a-zA-Z0-9\-\_\/\ ]*'

    # <"> <Any character except CTLs, DQUOTE> <">
    # CTL         =  <any ASCII control           ; (  0- 37,  0.- 31.)
    #                 character and DEL>          ; (    177,     127.)
    # DQOUTE = '"'
    # QSTR    = '"([^"]*)"'
    QSTR = QUOTED_STRING # use the definition from rfc822

    # *<Any character except CTLs, DQUOTE, ";", ":", ",">
    PTEXT   = '([^";:,]+)'

    # param-value = ptext / quoted-string
    PVALUE  = "(?:#{QSTR}|#{PTEXT})"

    # param = name "=" param-value *("," param-value)
    PARAM = ";(#{NAME})=((?:#{PVALUE})?(?:,#{PVALUE})*)"

    # V3.0: contentline  =   [group "."]  name *(";" param) ":" value
    # V2.1: contentline  = *( group "." ) name *(";" param) ":" value
    #
    #LINE = "((?:#{NAME}\\.)*)?(#{NAME})([^:]*)\:(.*)"
    # tcmalloc (used by ree) having memory issues with that one:
    #LINE = "^((?:#{NAME}\\.)*)?(#{NAME})((?:#{PARAM})*):(.*)$"
    #LINE = "^((?:#{NAME}\\.)*)?(#{NAME})((?:#{PARAM})*):"
    # We do not accept the V2.1 syntax.
    LINE = "^(#{NAME}\\.)?(#{NAME})((?:#{PARAM})*):"

    # date = date-fullyear ["-"] date-month ["-"] date-mday
    # date-fullyear = 4 DIGIT
    # date-month = 2 DIGIT
    # date-mday = 2 DIGIT
    DATE = '(\d\d\d\d)-?(\d\d)-?(\d\d)'

    # time = time-hour [":"] time-minute [":"] time-second [time-secfrac] [time-zone]
    # time-hour = 2 DIGIT
    # time-minute = 2 DIGIT
    # time-second = 2 DIGIT
    # time-secfrac = "," 1*DIGIT
    # time-zone = "Z" / time-numzone
    # time-numzome = sign time-hour [":"] time-minute
    TIME = '(\d\d):?(\d\d):?(\d\d)(\.\d+)?(Z|[-+]\d\d:?\d\d)?'

    # integer = (["+"] / "-") 1*DIGIT
    INTEGER = '[-+]?\d+'

    # QSAFE-CHAR = WSP / %x21 / %x23-7E / NON-US-ASCII
    #  ; Any character except CTLs and DQUOTE
    QSAFECHAR = '[ \t\x21\x23-\x7e\x80-\xff]'

    # SAFE-CHAR  = WSP / %x21 / %x23-2B / %x2D-39 / %x3C-7E / NON-US-ASCII
    #   ; Any character except CTLs, DQUOTE, ";", ":", ","
    SAFECHAR = '[ \t\x21\x23-\x2b\x2d-\x39\x3c-\x7e\x80-\xff]'
  end

end
