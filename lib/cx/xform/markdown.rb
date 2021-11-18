# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/xform/record'

# :COMMAND:
# MarkdownOut:
#   aliases: [md, markdown]
#   synopsis: Generate Markdown table lines.
#   args: []
#   opts: {}

module CX
  module Xform
    class MarkdownOut
      include OutputFormat, RecordOut, Xform
      
      def call input, env
        title = opts[:title] # TODO
        @cols = input.header.ordered
        align = Align.new
        align.set_cols!(@cols)
        output = make_output
        if include_header?
          output << format_row(align, @cols.map(&:to_s), :header)
          output << format_row(align, @cols.map{|_| '---'}, '-')
        end
        input.each do | row |
          output << format_row(align, row.vals(@cols), nil)
        end
        @cols = nil
        env[:content_type] = 'text/markdown' # 2016 RFC7763 at IETF
        output
      end

      def format_row align, row, fill
        row = row.map{|v| format_value(v)} unless fill == :header
        row = align.align_row(row, fill)
        [ '| '.dup << (row * ' | ') << " |\n" ]
      end
    end    
  end
end

