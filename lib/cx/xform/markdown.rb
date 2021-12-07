# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'
require 'cx/xform/align'


# :COMMAND:
# MarkdownOut:
#   aliases: [ md, md-, markdown ]
#   synopsis: Generate Markdown table lines.
#   suffixes: [ .md ]
#   args: []
#   opts:
#     title: Output title.
#     include-header: Include a header.

module CX
  module Xform
    class MarkdownOut
      include SelectColumns, OutputFormat, RecordOut
      
      def call input, env
        title = opts[:title] # TODO
        cols = column_args!(input).or_all!.columns
        align = Align.new
        align.set_cols!(cols)
        output = make_output
        if include_header?
          output << format_row(align, cols.map(&:to_s), :header)
          output << format_row(align, cols.map{|_| '---'}, '-')
        end
        input.each do | row |
          output << format_row(align, row.vals(cols), nil)
        end
        env[:content_type] ||= 'text/markdown' # IETF RFC7763 2016
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

