# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'

# :COMMAND:
# DelimitedIn:
#   aliases: [ -d ]
#   synopsis: Parse delimited records.
#   inverse: [ d- ]
#   args: []
#   opts:
#     field-sep=:   'Default: ",".'
#     record-sep=:  'Default: system newline.'

# :COMMAND:
# DelimitedOut:
#   aliases: [ d- ]
#   synopsis: Generate delimited records.
#   inverse: [ -d ]
#   args: []
#   has_column_args: true
#   opts:
#     field-sep=:   'Default: ",".'
#     record-sep=:  'Default: system newline.'
#     multi-sep=:   'Separator for enumerable values.  Default: ";".'

module CX
  module Xform
    class DelimitedIn
      include RecordIn
      def parse_record line
        line.split(@field_sep, -1)
      end
    end
    
    class DelimitedOut
      include SelectColumns, RecordOut
      def call input, env
        columns = column_args!(input).or_all!.columns
        output = make_output
        output.header.first.meta.type = :String
        input.each do | r |
          output << [ generate_record(columns, r) ]
        end
        output
      end
      
      def generate_record columns, r
        columns.map{|c| format_value(r[c])} * @field_sep << @record_sep
      end
    end
  end
end

