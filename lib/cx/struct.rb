require 'cx'

module CX
  module StructSupport
    def self.included target
      super
      target.extend ClassMethods
    end

    def from_hash!(h)
      h.each do | k, v |
        begin
          self[k] = v
        rescue NameError
        end
      end
      self
    end

    def members_map member = self.class.members
      members.map{|k| [k, yield(k, self[k])]}.to_h
    end
      
    module ClassMethods
      def new_from_hash h
        new(*values_from_hash(h))
      end
      
      def values_from_hash h
        h.values_at(*members)
      end

      def new_from_map
        new(*members.map{|k| yield(k)})
      end
    end
  end
end


