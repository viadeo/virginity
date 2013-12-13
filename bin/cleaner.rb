#!/usr/bin/env ruby
require "#{File.dirname(__FILE__)}/../lib_env"
require "virginity"
include Virginity

FAIL_FILE = File.open("fail.txt", "w")

def clean(vcard)
  Vcard.fix_and_clean(vcard)
end



def clean_in_dir(dir)
  dashes = "-"*40
  size = Dir.glob("#{dir}/*.vcf").size.to_f
  Dir.glob("#{dir}/*.vcf").sort.each_with_index do |f, i|
    puts ("%.2f\%" % (i.to_f / size*100.0)) if i % 500 == 0
    begin
      puts f
      clean(File.read(f))
    rescue => e
      puts "failed on #{f} - #{e.class} #{e}"
      puts File.read(f), dashes
      FAIL_FILE.puts "failed on #{f} - #{e.class} #{e}"
      FAIL_FILE.puts File.read(f), dashes
      FAIL_FILE.puts e.backtrace
      # raise
    end
  end
end


raise "expected an argument" if ARGV.first.nil?
raise "No such file or directory #{ARGV.first.inspect}" unless File.exists? ARGV.first

if File.file?(ARGV.first)
  puts clean(File.read(ARGV.first))
elsif File.directory?(ARGV.first)
  dir = ARGV.first
  unless Dir.glob("#{dir}/*.vcf").empty?
    clean_in_dir(dir)
  else
    Dir.glob("#{dir}/*").sort.each do |subdir|
      puts "folder: #{subdir}"
      clean_in_dir(subdir)
    end
  end
end

# DIR = "/media/usbstick/tmacedo/vcards2"
# (600..999).each do |num|
#   folder = DIR + "/" + num.to_s
#   puts "folder: #{folder}"
#   clean_in_dir(folder)
# end

FAIL_FILE.close
