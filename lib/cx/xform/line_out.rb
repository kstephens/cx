# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    module LineOut
      attr_accessor :col_sep, :row_sep, :multi_sep

      def initialize *args
        super
        @col_sep   = opts[:col_sep]   || ','
        @row_sep   = opts[:row_sep]   || "\n"
        @multi_sep = opts[:multi_sep] || ';'
      end
  
      def output
        @output ||=
          Table.new.header! Header.new << Column.new(:_LINE_).tap{|c| c.meta.type = ::String}
      end

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

