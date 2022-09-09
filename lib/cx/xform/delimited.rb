# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'

# :COMMAND:
# DelimitedIn:
#   aliases: [ -d ]
#   synopsis: Parse delimited records.
#   inverse: [ d- ]
#   arguments: []
#   options:
#     field-sep=:   'Default: ",".'
#     record-sep=:  'Default: system newline.'
#     record-cont-sep=:  'Separator for continued records.  Default: NONE.'

# :COMMAND:
# DelimitedOut:
#   aliases: [ d- ]
#   synopsis: Generate delimited records.
#   inverse: [ -d ]
#   arguments: []
#   has_column_args: true
#   options:
#     field-sep=:   'Default: ",".'
#     record-sep=:  'Default: system newline.'
#     multi-sep=:   'Separator for enumerable values.  Default: ";".'
#     record-cont-sep=:  'Separator for continued records.  Default: NONE.'

module CX
  module Xform
    class DelimitedIn
      include RecordInBase
      def parse_record line
        line.split(@field_sep_rx, -1)
      end
    end
    
    class DelimitedOut
      include SelectColumns, RecordOutBase
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

