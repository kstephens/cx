# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/xform/record'
require 'cx/xform/csv_safe'

# :COMMAND:
# CsvOut:
#   aliases:
#   synopsis: Generates CSV lines.
#   args: []
#   opts: {}

module CX
  module Xform
    class CsvIn
      include RecordIn, Xform
      def initialize!
        super
        @csv = CSVSafe.new(opts || {})
      end

      def parse_content str
        @csv.read StringIO.new(str)
      end
    end
    
    class CsvOut
      include RecordOut, Xform
      def initialize!
        super
        @csv = CSVSafe.new(opts || {})
      end
      
      def call input, env
        @cols = input.header.ordered
        output = make_output
        input.each do | r |
          output << [ line(r) ]
        end
        env[:content_type] = 'text/csv' # according to RFC 4180.
        @cols = nil
        output
      end
      
      def line r
        @csv.generate_line(@cols.map{|c| format_value(r[c])})
      end
    end
  end
end

