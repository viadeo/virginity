module Virginity

  module Params
    module Type


      class TypeArray < SerializingArray
        def initialize(field)
          @field = field
          super(@field.params("TYPE").map { |p| p.value }.uniq)
        end

#           def reload!
#             @array = Array.new(@field.params("TYPE").map { |p| p.value }.uniq)
#             self
#           end

        def rewrite!
          @field.params("TYPE").each {|t| @field.params.delete t }
          @array.each do |type|
            @field.params << Param.new('TYPE', type)
          end
        end

        # Locations are a subset of all the TYPE-params
        LOCATIONS = { "CELL" => "Mobile", "HOME" => "Home", "OTHER" => "Other", "WORK" => "Work" }
        def locations
          @array.select { |t| LOCATIONS.keys.include?(t)}
        end

        def locations=(locs)
          locations.each {|l| delete(l) }
          locs.each { |l| self << l }
        end
      end


      def types
        TypeArray.new(self)
      end

      def types=(array)
        types.replace(array)
      end

      def type=(str)
        self.types = str.split(/ /)
      end

      def add_type(thing)
        t = types
        t << thing unless t.include? thing
      end

      def remove_type(thing)
        types.delete(thing)
      end

      # =============================
      # Preferred
      def preferred?
        types.include? 'PREF'
      end

      def preferred=(val)
        if val
          add_type 'PREF'
        else
          remove_type 'PREF'
        end
      end

      # =============================
      # Location handling:
      def locations
        types.locations
      end

      def locations=(array)
        types.locations = array
      end

      def location
        locations.join(" ")
      end

      def location=(str)
        self.locations = str.split(/ /)
      end
    end

  end
end
