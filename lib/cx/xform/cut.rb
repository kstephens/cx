# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# Cut:
#   aliases: 
#   synopsis: Cut columns.
#   args: []
#   opts: {}

module CX
  module Xform
    class Cut
      include Xform
      def call input, env
        col_args = ColumnArgs.new.
          parse!(args).
          bind!(input.header).
          wildcards!.
          or_all!
        col_args.bound.each do | ca |
          # pp(ca: ca)
          ca.column = nil if (ca.opts[:order] || 0) < 0
        end

        # pp(args: args, col_args: col_args)
        columns = col_args.bound.map(&:column)
        
        output_columns = columns.map(&:dup)
        output_columns.each{|c| c.index = c.order = nil}
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

