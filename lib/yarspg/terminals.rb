# coding: utf-8
# Terminal definitions for EBNF Parser
module YARSPG::Terminals
  U_CHARS1         = Regexp.compile(<<-EOS.gsub(/\s+/, ''))
                       [\\u00C0-\\u00D6]|[\\u00D8-\\u00F6]|[\\u00F8-\\u02FF]|
                       [\\u0370-\\u037D]|[\\u037F-\\u1FFF]|[\\u200C-\\u200D]|
                       [\\u2070-\\u218F]|[\\u2C00-\\u2FEF]|[\\u3001-\\uD7FF]|
                       [\\uF900-\\uFDCF]|[\\uFDF0-\\uFFFD]|[\\u{10000}-\\u{EFFFF}]
                     EOS
  U_CHARS2         = Regexp.compile("\\u00B7|[\\u0300-\\u036F]|[\\u203F-\\u2040]", Regexp::FIXEDENCODING).freeze
  IRI_RANGE        = Regexp.compile("[[^<>\"{}|^`\\\\]&&[^\\x00-\\x20]]", Regexp::FIXEDENCODING).freeze
  UCHAR            = EBNF::LL1::Lexer::UCHAR

  STRING_LITERAL_QUOTE = /"([^\"\\\n\r]|#{UCHAR})*"/.freeze
  SIGN                 = %r([\+\-])u.freeze
  PN_CHARS_BASE        = %r([A-Z]|[a-z]|[0-9]|#{U_CHARS1})u.freeze
  PN_CHARS_U           = %r(_|(?:#{PN_CHARS_BASE}))u.freeze
  PN_CHARS             = %r(-|[0-9]|(?:#{PN_CHARS_U})|#{U_CHARS2})u.freeze
  STRING               = %r(#{STRING_LITERAL_QUOTE})u.freeze
  NUMBER               = %r((?:#{SIGN})?\d+(\.\d*)?)u.freeze
  BOOL                 = %r(true|false)u.freeze
  ALNUM_PLUS           = %r((?:#{PN_CHARS_BASE})(?:(?:(?:#{PN_CHARS})|\.)*(?:#{PN_CHARS}))?)u.freeze
  IRI                  = /<(?:(?:#{IRI_RANGE})|(?:#{UCHAR}))*>/u.freeze # prob with grammar
  DATE                 = %r(\d\d\d\d-\d\d-\d\d)u.freeze
  TIMEZONE             = %r((?:#{SIGN})?\d\d:\d\d)u.freeze
  TIME                 = %r(\d\d:\d\d:\d\d(?:#{TIMEZONE})?)u.freeze
  DATETIME            = %r((?:#{DATE})T(?:#{TIME}))u.freeze
  HEX                  = %r(\#x[0-9a-fA-F]+)u.freeze
  COMMENT              = /(?:#[^\n\r\r]*)/u.freeze
  WS                   = /(?:\s|(?:#{COMMENT}))+/m.freeze
end
