# encoding: UTF-8

# require "#{File.dirname(__FILE__)}/benchmark_helper"
require 'rubygems'
require "memprof"

text = <<end_text
fòó
bär
baß
end_text

Memprof.start
text.each_char { |ch| ch }
puts Memprof.stats
result = Memprof.stop

