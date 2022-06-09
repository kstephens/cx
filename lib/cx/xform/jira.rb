# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'


# :COMMAND:
# JiraOut:
#   aliases: [ jira ]
#   synopsis: Generate a Jira table lines.
#   suffixes: [ .jira.txt ]
#   has_column_args: true
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.csv // -h // jira'

module CX
  module Xform
    class JiraOut
      include SelectColumns, OutputFormat, RecordOut
      
      def call input, env
        title = opts[:title] # TODO
        cols = column_args!(input).or_all!.columns
        output = make_output
        if include_header?
          output << make_row(cols, "||")
        end
        input.each do | row |
          output << make_row(row.vals(cols), "|")
        end
        output
      end

      def make_row row, sep
        [ sep.dup << row.map{|c| escape(c)}.join(sep) << sep << "\n" ]
      end
      
      def escape s
        s.to_s.gsub(/[|]/, "\\|")
      end
    end
  end
end

