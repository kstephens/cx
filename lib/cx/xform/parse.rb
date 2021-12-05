# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/type'
require 'cx/xform/column_change'

# :COMMAND:
# Parse:
#   aliases: 
#   synopsis: Parse strings into richer types..
#   args: []
#   opts: {}

module CX
  module Xform
    class Parse
      include SelectColumns, Xform
      
      def call input, env
        columns = column_args!(input).or_all!.columns
        columns.each do | c |
          m = c.meta.clear!
          input.each do | r |
            case new_v = old_v = r[c]
            when nil
            when String
              if (new_v = Type.parse(old_v)) != nil?
                new_v = old_v
              end
            end
            m.update!(r[c] = new_v)
          end
          m.infer!
          m.type = m.type_inferred if m.type_inferred
        end
        input
      end
    end
  end
end

