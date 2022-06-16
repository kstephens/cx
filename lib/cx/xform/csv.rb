# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'
require 'cx/xform/csv_safe'

# :COMMAND:
# CsvIn:
#   aliases:
#   synopsis: Parses CSV lines.
#   suffixes: [ .csv ]
#   inverse: [ 'csv-' ]
#   args: []
#   opts:
#     separator=: 'Column separator: defaults to `","`.'

# :COMMAND:
# CsvOut:
#   aliases:
#   synopsis: Generates CSV lines.
#   suffixes: [ .csv ]
#   inverse: [ '-csv' ]
#   args: []
#   opts:
#     separator=: 'Column separator: defaults to `","`.'
#   examples:
#     - cx in SOME.csv // csv- --separator="\x09"

module CX
  module Xform
    class CsvIn
      include RecordInBase
      
      def initialize!
        super
        @csv = CSVSafe.new(opts || {})
        self
      end

      def parse_record str
        @csv.parse_line(str)
      end
    end
    
    class CsvOut
      include RecordOutBase
      
      def call input, env
        @csv = CSVSafe.new(opts || {})
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

