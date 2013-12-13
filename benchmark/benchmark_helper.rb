$:.unshift "#{File.dirname(__FILE__)}/../lib/"
require "rubygems"
require 'bundler/setup'
Bundler.require

require "virginity"
include Virginity

VCARDS_ROOT = "#{File.dirname(__FILE__)}/../test/data/"

require 'benchmark'
