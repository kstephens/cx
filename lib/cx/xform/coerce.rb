# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/type'
require 'cx/xform/column_change'

# :COMMAND:
# Coerce:
#   aliases: 
#   synopsis: Coerce columns by inferred types.
#   args: []
#   opts: {}

module CX
  module Xform
    class Coerce
      include SelectColumns, Xform
      
      def call input, env
        columns = column_args!(input).or_all!.columns
        
        columns.each do | c |
          m = c.meta.clear!
          if type = c.meta.type_object
            input.each do | r |
              new_v = old_v = r[c]
              new_v = type_object.coerce(old_v)
              new_v = old_v if new_v.nil?
              m.update!(r[c] = new_v)
            end
            c.meta.infer!
          end
        end
        input
      end
    end
  end
end

