# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/xform/line_out'

module CX
  module Xform
    class MarkdownOut
      include LineOut, Xform
      # :COMMAND:
      # MarkdownOut:
      #   name: markdown-
      #   aliases: md, markdown
      #   synopsis: Generate Markdown table line.
      #   args: []
      #   opts: {}
      
      def call input, env
        title = opts[:title]
        align = Align.new
        align.header!(input.header)
        output << format_row(align, input.header.map(&:to_s), :header)
        output << format_row(align, input.header.map{|_| '---'}, '-')
        input.each do | row |
          output << format_row(align, row, nil)
        end
        env[:content_type] = 'text/markdown' # 2016 RFC7763 at IETF
        output
      end

      def format_row align, row, fill
        row = row.map{|c, v| format_value(v)} unless fill == :header
        row = align.align_row(row, fill)
        [ '| '.dup << (row * ' | ') << " |\n" ]
      end
    end    
  end
end

