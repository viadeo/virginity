require "virginity/dir_info/content_line"
require "virginity/vcard/cleaning"
require "virginity/vcard21/writer"
require "virginity/vcard/field_values"

module Virginity

  # As a Vcard is a special type of DirectoryInformation, so is the Field a special type of ContentLine.
  # A Field in Virginity is more content aware than a ContentLine. It knows what sort of content to expect for BDAY or ADR (respectively date or text, and a structured text value) and it provides the according methods that handle the differences in encoding.
  class BaseField < ContentLine
    include Vcard21::Writer
    include FieldCleaning

    def self.merger(left, right)
      # ContentLine.merger returns a ContentLine, let's convert it to a field again.
      Field.parse(super)
    end

    # is this field a preferred field?
    TYPE = "TYPE"
    PREF = /^pref$/i
    def pref?
      params(TYPE).any? { |p| p.value =~ PREF }
    end

    BEGIN_REGEX = /^BEGIN$/i
    END_REGEX = /^END$/i

    # Fields can be sorted
    def <=>(other)
      # BEGIN and END are special. and Virginity does not support nested vcards
      return -1 if name =~ BEGIN_REGEX or other.name =~ END_REGEX
      return 1 if name =~ END_REGEX or other.name =~ BEGIN_REGEX
      unless (diff = (name <=> other.name)) == 0
        diff
      else
        unless (diff = (pref? ? 0 : 1) <=> (other.pref? ? 0 : 1)) == 0
          diff
        else
          to_s <=> other.to_s
        end
      end
    end

    # fields ARE content_lines but most often one should not deal with the value. In virtually all cases value contains some encoded text that is only useful when decoded as text or a text list.
    def value
      $stderr.puts "WARNING, you probably don't want to read value, if you do, please use #raw_value. Called from: #{caller.first}"
      raw_value
    end

    alias_method :raw_value=, :value=
    def value=(new_value)
      $stderr.puts "WARNING, you probably don't want to write value, if you do, please use #raw_value=. Called from: #{caller.first}"
      raw_value=(new_value)
    end

    def ==(other)
      group == other.group &&
        has_name?(other.name) &&
        params == other.params &&
        raw_value == other.raw_value
    end


    # a Hash to containing name => class
    @@field_register = Hash.new(self)

    def self.field_register
      @@field_register
    end

    def self.named(name)
      if registered? name
        self[name].new(name)
      else
        new(name)
      end
    end

    # redefine ContentLine#parse to gain a few nanoseconds and initialize the correct Field using the register
    def self.parse(line)
      if line.is_a? ContentLine
        self[line.name].new(line.name, line.raw_value, line.params, line.group)
      else
        group, name, params, value = line_parts(line.to_s)
        self[name].new(name, value, params, group, :no_deep_copy => true)
      end
    end

    class << self
      alias_method :from_line, :parse
    end

    # register a new field name with the class that should be used to represent it
    def self.register_field(name, field_class)
      raise "#{name} is already registered" if registered?(name)
      @@field_register[name.to_s.upcase] = field_class
    end

    # when called from a Field-descendant, this method registers that class as the one handling fields with a name in names
    def self.register_for(*names)
      names.each { |name| register_field(name, self) }
    end

    # is name registered?
    def self.registered?(name)
      @@field_register.keys.include?(name.to_s.upcase)
    end

    def self.unregister(name)
      @@field_register[name.to_s.upcase] = nil
    end

    # TODO: figure out if we really need upcase here
    def self.[](name)
      @@field_register[name.to_s.upcase]
    end

#     # a hash mapping field-names/types to Field-classes
    def self.types
      @@field_register.dup
    end
  end


end
