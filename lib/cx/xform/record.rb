# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    module RecordBase
      include Xform
      attr_accessor :col_sep, :row_sep, :multi_sep
    
      def initialize *args
        super
        @field_sep    = opts[:field_sep]   || ","
        @record_sep   = opts[:record_sep]  || /\n\r?/
        @multi_sep    = opts[:multi_sep]   || ";"
      end

      def make_record_table cols = []
        cols = cols.map{|c| Column.new(c).tap{|c| c.meta.type = ::String}}
        Table.new([],Header.new(cols))
      end
    end

    module RecordIn
      include RecordBase
      def call input, env
        raise_ ArgumentError, "expected one input row" unless input.size == 1
        raise_ ArgumentError, "expected one input col" unless input.header.size == 1
        rows = parse_content(input[0][0])
        header = Header.
          new(rows.first ? rows.first.size : 0).
          each{|c| c.meta.type = ::String}
        output = Table.new(rows, header)
        output
      end
    end
    
    module RecordOut
      include RecordBase
      def make_output
        make_record_table([:_RECORD_])
      end

=begin
      def write str
        raise_ "write: not a string : #{str.class}"
        output << [ str ]
      end
      alias :<< :write
=end

      def format_value v
        case v
        when nil
          nil
        when Enumerable
          v.map{|e| format_value(e).to_s} * multi_sep
        else
          v.to_s
        end
      end
    end
  end
end

