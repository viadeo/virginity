require 'virginity/bnf'
require 'virginity/dir_info/line_folding'
require 'virginity/dir_info/content_line'
require 'virginity/dir_info/query'

require 'virginity/vcard21/reader'

$KCODE = 'U' unless defined? Encoding::UTF_8

module Virginity

  # see rfc 2425, MIME Content-Type for Directory Information.
  #
  # Basically a DirectoryInformation-object is a collection of lines (see ContentLine)
  class DirectoryInformation
    include Query
    extend Virginity::Vcard21::Reader
    extend Encodings
    attr_reader :lines

    # decode directory information text
    # TODO accept an array of lines as the argument, make a special from_string(string="")
    def initialize(string = "")
      raise "expected a string but found #{string.inspect}, a #{string.class}" unless string.is_a? String
      @lines = LineFolding::unfold_and_split(string).map do |line|
        ContentLine.parse(line)
      end
    end

    # string representation
    def encode
      LineFolding::fold(unfolded)
    end
    alias_method :to_s, :encode

    # replace _all_ lines
    def lines=(replace_lines)
      @lines = replace_lines.to_a.map { |line| ContentLine.parse(line.to_s) }
    end

    def inspect
      "#<#{self.class}:#{object_id}>"
    end

    def delete(*lines_to_delete)
      lines_to_delete.compact.map { |line| lines.delete(line) }.compact
    end

    # remove only this exact content line identified by its object-id
    def delete_content_line(cl)
      lines.delete_if { |line| line.object_id == cl.object_id }
    end

    # append a line
    def <<(line)
      lines << ContentLine.parse(line.to_s)
    end
    alias_method :push, :<<

    # string representation that is not folded (see LineFolding)
    LF = "\n"
    def unfolded
      @lines.join(LF) << LF
    end

    def pretty_print(q)
      q.text unfolded
    end

    # equallity is defined as having the same lines
    def ==(other)
      return false if other.class != self.class
      # checking for lines.size is an optimisation
      @lines.size == other.lines.size and @lines.sort == other.lines.sort
    end

    # eql? is defined as being of the same class (not a descendent class like Vcard) and having the same lines
    def eql?(other)
      self.class == other.class and self == other
    end

    # are all @lines also present in other?
    def subset_of?(other)
      @lines.all? do |line|
        other.first_match(line.to_s)
      end
    end

    def superset_of?(other)
      other.subset_of?(self)
    end
  end
end
