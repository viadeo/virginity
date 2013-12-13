require 'bundler/setup'
Bundler.require

require "virginity"
include Virginity

VCARDS_ROOT = "#{File.dirname(__FILE__)}/data/"

Encoding.default_internal = Encoding::UTF_8 if defined? Encoding::UTF_8

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
