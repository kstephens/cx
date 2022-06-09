# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/column_args'
require 'cx/compare'

# :COMMAND:
# Sort:
#   aliases: s
#   synopsis: Sorts by specified columns.
#   has_column_args: true
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.csv // -h // sort d  // h-'
#     - 'cx in SOME.csv // -h // sort    // h-'
#     - 'cx in SOME.csv // -h //            sort a    // h-'
#     - 'cx in SOME.csv // -h // parse   // sort a    // h-'
#     - 'cx in SOME.csv // -h // parse   // sort a:-  // h-'

module CX
  module Xform
    class Sort
      include SelectColumns, Xform
      
      def call input, env
        column_args!(input).or_all!
        @order = column_args.map{|ca| ca.opts[:order] || 1}
        columns = column_args.args.map(&:column)
        rows_with_keys = input.map do | row |
          [ columns.map{|c| row[c]}, row ]
        end
        rows_with_keys.sort! do | a, b |
          # pp(a: a, b: b)
          cmp_vals(a.first, b.first)
        end
        input.set_rows!(rows_with_keys.map{|rk| rk[1]})
        @order = rows_with_keys = nil
        input
      end
    end

    def cmp_vals a_, b_
      a_.each_with_index do | a, i |
        cmp = Compare.compare(a, b_[i])
        return cmp * @order[i] unless cmp.zero?
      end
      0
    end
  end
end

