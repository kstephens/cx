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
#   has_column_args: true
#   args: []
#   opts:
#     title=: 'Output title (caption).  Default: none.'
#     include-header: 'Include a header.  Default: true.'
#   examples:
#     - 'cx in SOME.csv // -h // markdown'
#     - 'cx in SOME.csv // -h // parse // md'
#     - 'cx in SOME.csv // -h // parse // md --title=SOME.CSV'
#     - 'cx in SOME.csv // -h // parse // md --title=SOME.CSV --no-include-header'

module CX
  module Xform
    class MarkdownOut
      include SelectColumns, OutputFormat, RecordOut
      
      def call input, env
        cols = column_args!(input).or_all!.columns.sort_by(&:order)
        @align = Align.new
        @align.set_cols!(cols)
        output = make_output
        if include_header?
          output << format_row(cols.map(&:to_s), :header)
          output << format_row(cols.map{|_| '---'}, '-')
        end
        input.each do | row |
          output << format_row(row.vals(cols), nil)
        end
        if title = opts[:caption] || opts[:title]
          output << [ ("[ ".dup << title.to_s << " ]\n") ]
          end
        env[:content_type] ||= 'text/markdown' # IETF RFC7763 2016
        @align = nil
        output
      end

      def format_row row, fill
        row = row.map{|v| format_value(v)} unless fill == :header
        row = @align.align_row(row, fill)
        [ '| '.dup << (row * ' | ') << " |\n" ]
      end
    end
  end
end

