require "#{File.dirname(__FILE__)}/benchmark_helper"
require "benchmark"

v = Vcard.new
v << Field::Tel.at_random
v << Field::Tel.at_random

puts "cloning a vCard:"
Benchmark.bm(10) do |bm|
  bm.report("new(to_s)") { 1000.times { Vcard.new(v.to_s) } }
  bm.report("Marshal") { 1000.times { Marshal::load(Marshal::dump(v)) } }
end


paramstring = ";"+"TYPE=HOME,CELL,OTHER,FAX"
params = Param.params_from_string(paramstring)

puts "cloning params:"
Benchmark.bm(10) do |bm|
  bm.report("new(to_s)") { 3000.times { Param::params_from_string(Param::simple_params_to_s(params)) } }
  bm.report("Marshal") { 3000.times { Marshal::load(Marshal::dump(params)) } }
end
