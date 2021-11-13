# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

# :COMMAND:
# Transpose:
#   name: transpose
#   aliases:
#   synopsis: Transpose rows and columns.
#   args: []
#   opts:

module CX
  module Xform
    class Transpose
      include Xform
      def call input, env
        input_cols = input.header.ordered

        @include_header = false
        width, height = input.size, input_cols.size
        height += 1 if @include_header
        rows = (0 ... height).map{|_| [nil] * width}

        ri = -1
        input.each_with_index do | row |
          ri += 1
          ci = -1
          rows[ci += 1][ri] = input_cols[ri] if @include_header
          input_cols.each do | col |
            rows[ci += 1][ri] = row[col]
          end
        end
        
        header = Header.new
        (0 ... width).each{|i| header << Column.new(:"_COL_#{i}")}
        output = Table.new(rows, header)
        output
      end
    end
  end
end

