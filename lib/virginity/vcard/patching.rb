require 'forwardable'
module Virginity
  class Vcard < DirectoryInformation
    # before: TEL;TYPE=HOME:1234
    # after: TEL;TYPE=HOME:1233
    # --- clearly fixing a typo so: ---
    # update("TEL:1234", :value => 1233)

    # before: TEL;TYPE=HOME:1234
    # after: TEL;TYPE=HOME,WORK:1234
    # --- params changed ---
    # update("TEL:1234", :add_param => "TYPE=WORK")

    # before: TEL;TYPE=HOME:1234
    # after: TEL;TYPE=WORK:1234
    # --- params changed ---
    # update("TEL:1234", :remove_param => "TYPE=HOME", :add_param => "TYPE=WORK")

    # before: TEL;TYPE=HOME:1234
    # after: TEL;TYPE=WORK:1233
    # --- someone removed the home phone and added a new number for work ---
    # remove("TEL:1234")
    # add("TEL;TYPE=WORK:1233")
    module Patching
      class IllegalPatch < Error; end

      def patch!(diff)
        diff.apply(self)
        self
      end

      def self.diff(before_card, after_card)
        Diff.diff(before_card, after_card)
      end


      # the base class
      class Patch
        def self.query_for_line(line)
          line.name + ":" + line.raw_value
        end

        def self.query_from_string(query_string)
          q = Field.parse(query_string)
          # at this moment all our queries are like "name : raw_value"
          query = { :name => q.name }
          if q.respond_to? :values
            query[:values] = q.values.to_a
          elsif q.respond_to? :text
            query[:text] = q.text
          else
            query[:raw_value] = q.raw_value
          end
          query
        end

        def field_from_query(query)
          value = query.reject { |k, v| k == :name }
          Field.named(query[:name]) do |f|
            value.each do |k,v|
              f.send(k+'=', v)
            end
          end
        end

        def apply(vcard)
          raise "responsibility of subclass"
        end

        def self.normalize_vcard!(vcard)
          vcard.clean_orgs! # orgs are of variable length, but ordered, they need normalizing before we can compare them
          # normalize categories and nicknames (actually every unpackable field)
          vcard.fields.each do |field|
            vcard.unpack_field!(field) if field.respond_to?(:unpacked)
            field.clean!
            field.params.sort!
          end
          # remove double lines
          vcard.clean_same_value_fields!
          vcard.add("N") unless vcard.lines_with_name("N").any?
          vcard.clean_name!
          vcard
        end
      end


      # a Diff is a collection of changes, I think we can even nest them which might be a cool way of combining them
      class Diff < Patch
        attr_reader :changes
        extend Forwardable
        def_delegators :@changes, :push, :<<, :empty?, :size

        def initialize(*changes)
          @changes = changes
        end

        def self.diff(before_card, after_card)
          patch = Diff.new
          before, after = before_card.deep_copy, after_card.deep_copy
          normalize_vcard!(before)
          normalize_vcard!(after)
          before.lines.each do |line|
            # if the exact same line is in after then we can stop processing this line
            # this will of course always happen for begin:vcard, end:vcard
            next unless after.delete(line).empty?
            q = query_from_string(line)
            if x = after.find_first(q)
              patch << Update.diff_lines(line, x, :query => q)
              after.delete(x)
            #else if "there is a line with just one or 2 characters difference in the value" or "only insignificant characters changed, like dashes in telephone numbers"
              # patch << Update.diff_lines(line, x, :query => q)
              # after.delete(x)
            else
              patch << Remove.new(q)
            end
          end
          # what is left in after should be added
          after.lines.each { |line| patch << Add.new(line.to_s) }
          patch
        end

        def apply(vcard)
          Patch::normalize_vcard!(vcard)
          @changes.each { |change| change.apply(vcard) }
        end

        def to_s
          @changes.join("\n")
        end

        def pretty_print(q)
          @changes.each do |change|
            pp change
          end
        end
      end


      # to add a field
      class Add < Patch
        attr_accessor :field
        def initialize(line)
          @field = Field.parse(line)
        end

        def apply(vcard)
          vcard.add_field(@field)
        end

        def to_s
          "Add(#{@field.inspect})"
        end

        def pretty_print(q)
          q.text "Add #{@field}"
        end
      end


      # to remove fields matching a query
      class Remove < Patch
        attr_accessor :query
        def initialize(query)
          @query = query
        end

        def apply(vcard)
          vcard.delete(*vcard.where(@query))
        end

        def to_s
          "Remove(#{@query.inspect})"
        end

        def pretty_print(q)
          q.text "Remove #{@query}"
        end
      end


      # to update field matching the query
      # for automatically generated diffs this will usually only entail updates to params
      # there is an alternative action that will be executed if there is no field to update
      class Update < Patch
        attr_accessor :query, :updates, :alternative
        def initialize(query, updates, alternative = nil)
          @query = query
          @updates = updates
          @alternative = alternative
        end

        def self.diff_lines(before, after, options = {})
          Update.new(
            options[:query] || Patch::query_from_string(before),
            line_diff(before, after),
            Add.new(after)
          )
        end

        COLON = ":"
        SEMICOLON = ";"
        def update_field!(field)
          @updates.each_pair do |key, value|
            case key
            when :value
              field.raw_value = value
            when :add_param
              # params_from_string returns an array of params
              field.params += Param::params_from_string(value + COLON)
            when :remove_param
              Param::params_from_string(value + COLON).each do |param_to_delete|
                field.params.delete_if { |p| p == param_to_delete }
              end
            else
              raise IllegalPatch, "#{key}, #{value}"
            end
          end
        end

        def apply(vcard)
          to_update = vcard.where(@query)
          if to_update.empty?
            # if the field has been deleted in the meantime on the server, the patch adds it again
            # to_update << vcard.add_field(field_from_query(@query)) if to_update.empty?
            @alternative.apply(vcard) unless @alternative.nil?
          else
            to_update.each { |field| update_field!(field) }
          end
        end

        def to_s
          s = "Update(#{@query.inspect}, #{@updates.map {|k,v| "#{k}(#{v.inspect})" }.join(", ")})"
          if @alternative
            s << " else { #{alternative} }"
          end
        end

        def pretty_print(q)
          q.text "Replace #{query} with #{@updates.map {|k,v| "#{k}(#{v.inspect})" }.join(", ")})"
          if @alternative
            q.text " else { #{alternative} }"
          end
        end

      protected
        # before and after are content lines
        def self.line_diff(before, after)
          patch = {}
          patch[:value] = after.raw_value unless before.raw_value == after.raw_value
          unless (to_remove = before.params - after.params).empty?
            patch[:remove_param] = Param.params_to_s(to_remove)
          end
          unless (to_add = after.params - before.params).empty?
            patch[:add_param] = Param.params_to_s(to_add)
          end
          patch
        end
      end

    end
  end
end
