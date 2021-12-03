# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/column_args'

# :COMMAND:
# Replace:
#   aliases: sub
#   synopsis: Replace by regex.
#   args: []
#   opts:

module CX
  module Xform
    class Replace
      include SelectColumns, Xform
      
      def call input, env
        column_args!(input).or_all!
        
        @cleared = Set.new
        
        fns = column_args.map{|arg| replace_fn input.header, arg}
        input.select! do | row |
          fns.each {|f| f.call(row) }
        end

        @cleared = nil
        input
      end
    end
    
    def replace_fn header, col_arg
      search  = col_arg.args[0] || opts[:search]
      replace = col_arg.args[1] || opts[:replace] || ''
      rx = Regexp.new(search)

      global = opts[:global] || col_arg.opts[:global] || col_arg.opts[:g]
      
      c = col_arg.column
      lambda do | row |
        old_v = row[c].to_s
        new_v = global ? old_v.gsub(rx, replace) : old_v.sub(rx, replace)
        if old_v != new_v
          unless @cleared.include?(c)
            @cleared << c
            c.meta.clear!
            c.meta.type = :String
            c.meta.type_inferred = nil
          end
          row[c] = new_v
        end
      end
    end
  end
end

