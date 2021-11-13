# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

# :COMMAND:
# Transpose:
#   aliases:
#   synopsis: Transpose rows and columns.
#   args: []
#   opts:
#     include-header: Include header in first column.

module CX
  module Xform
    class Transpose
      include Xform
      
      def initialize!
        super
        @include_header = opts.or_default(:include_header, true)
      end
      
      def call input, env
        input_cols = input.header.ordered

        width, height = input.size, input_cols.size
        width += 1 if @include_header
        rows = (0 ... height).map{|_| [nil] * width}

        if @include_header
          input_cols.each_with_index do | col, ci |
            rows[ci][0] = col
          end
        end
        
        input.each_with_index do | row, ri |
          ri += 1 if @include_header
          input_cols.each_with_index do | col, ci |
            rows[ci][ri] = row[col]
          end
        end
        
        header = Header.new
        (0 ... width).each{|i| header << Column.new(:"_COL_#{i + 1}")}
        output = Table.new(rows, header)
        output
      end
    end
  end
end

