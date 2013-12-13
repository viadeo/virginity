require "#{File.dirname(__FILE__)}/benchmark_helper"
require "benchmark"
require "measurebation"

# TODO: width_first_line should be an option IMO
def old_fold_quoted_printable(qp_text, width = 76, width_first_line = nil, options = {})
  return qp_text unless width > 5
  line_ending = (options[:windows_line_endings] ? "\r\n" : "\n")
  scanner = StringScanner.new(qp_text)
  folded = ""
  pos = 0
  w = width_first_line || width
  while !scanner.eos?
    char = scanner.get_byte
    if char == "="
      char << scanner.get_byte
      char << scanner.get_byte
    end
    pos += char.size
    if pos > w - 3 # "=\r\n".size => 3
      folded << ("=" + line_ending)
      w = width
      pos = char.size
    end
    folded << char
  end
  folded
end

QPCHAR = /[^=]|=[\dABCDEF]{2}/
QPFOLD = "=\r\n"
def new_fold_quoted_printable(qp_text, width = 76, initial_position = 0) # initial_position = 0)
  return qp_text unless width > 5
  pos = initial_position.to_i
  scanner = StringScanner.new(qp_text)
  folded = ""
  while !scanner.eos?
    char = scanner.scan(QPCHAR)
    charsize = char.size
    if pos + charsize > width - 3
      folded << QPFOLD
      pos = 0
    end
    folded << char
    pos += charsize
  end
  folded
end



@line = "=D0=95=D0=BB=D1=8C=D1=86=D0=B8=D0=BD=D0=B0;=C3=9Er=C3=BA=C3=B0r;=D0=95=D0=BB=D1=8C=D1=86=D0=B8=D0=BD=D0=B0;=D0=95=D0=BB=D1=8C=D1=86=D0=B8=D0=BD=D0=B0;"

puts '-'*76+'|'
puts old_fold_quoted_printable(@line)
puts "."*10 + new_fold_quoted_printable(@line, 76, 10)

puts "qp folding:"
Benchmark.bm(10) do |bm|
  bm.report("old") { 3000.times { old_fold_quoted_printable(@line) } }
  bm.report("new") { 3000.times { new_fold_quoted_printable(@line) } }
end
