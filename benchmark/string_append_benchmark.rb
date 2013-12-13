require "#{File.dirname(__FILE__)}/benchmark_helper"
require "benchmark"

x = ""
y = "b"

puts "+ VS <<"
Benchmark.bm(10) do |bm|
  bm.report("+") { 100_000.times { x << y + '.' unless y.nil? } }
  bm.report("<<") { 100_000.times { x << y << '.' unless y.nil? } }
end

puts x