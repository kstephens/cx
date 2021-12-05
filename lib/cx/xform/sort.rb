# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/column_args'
require 'cx/compare'

# :COMMAND:
# Sort:
#   aliases: s
#   synopsis: Sorts by specified columns.
#   args: []
#   opts:

module CX
  module Xform
    class Sort
      include SelectColumns, Xform
      
      def call input, env
        column_args!(input).or_all!
        
        @to_s_cache = Hash.new do |h, k|
          String === s ? s : h[k] = k.to_s.freeze
        end
        @order = column_args.args.map{|c| c.opts[:order] || 1}
        columns = column_args.columns
        rows_with_keys = input.map do | row |
          [ columns.map{|c| row[c]}, row ]
        end
        rows_with_keys.sort! do | a, b |
          cmp_vals(a.first, b.first)
        end
        input.set_rows!(rows_with_keys.map{|rk| rk[1]})

        @to_s_cache = @order = rows_with_keys = nil
        input
      end
    end

    def cmp_vals a_, b_
      a_.each_with_index do | a, i |
        cmp = Compare.compare(a, b_[i])
        return @order[i] * cmp unless cmp.zero?
      end
      0
    end
  end
end

