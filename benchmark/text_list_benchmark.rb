require "#{File.dirname(__FILE__)}/benchmark_helper"
require "benchmark"
require "measurebation"

COMMA = ","
SEMICOLON = ";"
BACKSLASH = "\\"

def self.old_decode_text_list(text_list, separator = SEMICOLON)
  strings = []
  state = :normal # there are two states: :normal and :escaped
  string = ""
  text_list.each_char do |char|
    if state == :escaped
      string << (%w(n N).include?(char) ? LF : char)
      state = :normal
    else
      case char
      when BACKSLASH
        state = :escaped
      when separator
        strings << string
        string = ""
      else
        string << char
      end
    end
  end
  strings << string
  strings
end

SEPARATOR_REGEXP = {}
def self.separator_regexp(separator)
  SEPARATOR_REGEXP[separator] ||= Regexp.new("[^\\#{separator}\\\\]*")
end

def self.new_decode_text_list(text_list, separator = SEMICOLON)
  special = separator_regexp(separator)
  list = []
  text = ""
  s = StringScanner.new(text_list)
  while !s.eos?
    text << s.scan(special)
    break if s.eos?
    case s.getch
    when BACKSLASH
      char = s.getch
      text <<  (char.casecmp('n') == 0 ? LF : char)
    when separator
      list << text
      text = ""
    else
      raise "read #{s.matched.inspect} at #{s.pos} in #{s.string}, #{s.string.size}"
    end
  end
  list << text
  list
end

@line = "XYZ;Sicherheitszentrale;;\n\ö;"

puts '-'*76+'|'
puts old_decode_text_list(@line).inspect
puts new_decode_text_list(@line).inspect

puts "decoding text list:"
Benchmark.bm(10) do |bm|
  n = 2_0000
  bm.report("old") { n.times { old_decode_text_list(@line) } }
  bm.report("new") { n.times { new_decode_text_list(@line) } }
end


Benchmark.bm(10) do |bm|
  char = 'N'
  n = 100_0000
  bm.report("==") { n.times { char == 'n' || char == 'N' ? "\n" : char } }
  bm.report("include") { n.times { %w(n N).include?(char) ? "\n" : char } }
  bm.report("casecmp == 0") { n.times { char.casecmp('n') == 0 ? "\n" : char } }
  bm.report("case") do
    n.times do
      case char
      when 'n', 'N'
        "\n"
      else
        char
      end
    end
  end
end