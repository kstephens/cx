# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# Cut:
#   aliases: 
#   synopsis: Cut columns.
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.csv // -h // cut a,d    // h-'
#     - 'cx in SOME.csv // -h // cut d,@    // h-'
#     - 'cx in SOME.csv // -h // cut @,b:-  // h-'

module CX
  module Xform
    class Cut
      include SelectColumns, Xform
      
      def call input, env
        column_args!(input).or_all!
        column_args.bound.each do | ca |
          # pp(ca: ca)
          ca.column = nil if (ca.opts[:order] || 0) < 0
        end

        # pp(args: args, col_args: col_args)
        columns = column_args.bound.map(&:column)
        
        output_columns = columns.map(&:dup)
        output_columns.each(&:clear!)
        header = Header.new(output_columns)
        output = Table.new([], header)
        input.each do | r |
          o = columns.map do | c |
            r[c]
          end
          output << o
        end
        output
      end
    end
  end
end

