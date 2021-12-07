# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# Cut:
#   aliases: 
#   synopsis: Cut columns.
#   args: []
#   opts: {}
#   has_column_args: true
#   examples:
#     - cx in SOME.csv // -h // cut a,d
#     - cx in SOME.csv // -h // cut b a c
#     - cx in SOME.csv // -h // cut c:-
#     - cx in SOME.csv // -h // cut 'a,*'
#     - cx in SOME.csv // -h // cut 'd,*'
#     - cx in SOME.csv // -h // cut '*,b:-'

module CX
  module Xform
    class Cut
      include SelectColumns, Xform
      
      def call input, env
        # Split args by ','
        args.map!{|a| a.split(/\s*,\s*/)}.flatten!
        
        column_args!(input).or_all!
        column_args.bound.each do | ca |
          ca.column = nil if ca.opts[:negate] || (ca.opts[:order] || 0) < 0
        end

        columns = column_args.bound.map(&:column)
        
        output_columns = columns.map(&:dup).each(&:clear!)
        header = Header.new(output_columns)
        output = Table.new([], header)
        input.each do | r |
          output << columns.map do | c |
            r[c]
          end
        end
        output
      end
    end
  end
end

