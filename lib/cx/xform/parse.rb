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
      include ColumnChange, SelectColumns, Xform
      
      def call input, env
        change_start!
        columns = column_args!(input).or_all!.columns
        
        input.each do | r |
          columns.each do | c |
            new_v = Type.parse(old_v = r[c])
            new_v = old_v if new_v.nil?
            change_maybe!(r, c, old_v, new_v) do
              c.meta.clear!
              c.meta.type = nil # new_v.class
              c.meta.type_inferred = nil
            end
          end
        end
        input
      end
    end
  end
end

