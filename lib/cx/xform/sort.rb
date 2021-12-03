# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/column_args'

# :COMMAND:
# Sort:
#   aliases: s
#   synopsis: Sorts by specified columns.
#   args: []
#   opts:

module CX
  module Xform
    class Sort
      include Xform
      
      def call input, env
        @to_s_cache = Hash.new do |h, k|
          String === s ? s : h[k] = k.to_s.freeze
        end
        col_args = ColumnArgs.new.
          parse!(args).
          bind!(input.header).
          or_all!
        @order = col_args.args.map{|c| c.opts[:order] || 1}
        columns = col_args.columns
        rows_with_keys = input.map do | row |
          [ columns.map{|c| row[c]}, row ]
        end
        rows_with_keys.sort! do | a, b |
          cmp_vals(a.first, b.first)
        end
        input.set_rows!(rows_with_keys.map{|rk| rk[1]})
        # GC
        @to_s_cache = @order = rows_with_keys = nil
        input
      end
    end

    def cmp_vals a_, b_
      a_.each_with_index do | a, i |
        b = b_[i]
        case
        when a.nil? && b.nil?
        when a.nil?
          return - @order[i]
        when b.nil?
          return @order[i]
        else
          cmp = case
                when a.class == b.class
                  a <=> b
                else
                  @to_s_cache[a] <=> @to_s_cache[b]
                end
          return @order[i] * cmp unless cmp.zero?
        end
      end
      0
    end
  end
end

