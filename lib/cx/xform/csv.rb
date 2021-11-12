# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/xform/line_out'
require 'cx/xform/csv_safe'

module CX
  module Xform
    class CSVOut
      include LineOut, Xform
      # :COMMAND:
      # CSVOut:
      #   name: csv-out
      #   aliases: csv-
      #   synopsis: Generates CSV lines.
      #   args: []
      #   opts: {}
      
      def initialize!
        super
        @csv = CSVSafe.new(opts || {})
      end
      
      def call input, env
        @cols = input.header.ordered
        input.each do | r |
          output << line(r)
        end
        env[:content_type] = 'text/csv' # according to RFC 4180.
        @cols = nil
        output
      end
      
      def line r
        [ @csv.generate_line(@cols.map{|c| format_value(r[c])}) ]
      end
    end
  end
end

