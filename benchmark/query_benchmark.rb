require "#{File.dirname(__FILE__)}/benchmark_helper"
require "benchmark"

v = Vcard.new
v << Field::Tel.at_random
v << Field::Tel.at_random

# puts v.query("TEL") == v.query2("TEL")

puts "querying a vCard:"
Benchmark.bmbm(12) do |bm|
  bm.report("query") { 3000.times { v.query("TEL") } }
#   bm.report("query object") { 3000.times { v.query2("TEL") } }
end

