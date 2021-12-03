# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'

# :COMMAND:
# DelimitedIn:
#   aliases: [ -d ]
#   synopsis: Parse delimted records
#   args: []
#   opts: {}

# :COMMAND:
# DelimitedOut:
#   aliases: [ d- ]
#   synopsis: Generate delimited records.
#   args: []
#   opts: {}

module CX
  module Xform
    class DelimitedIn
      include RecordIn
    end
    
    class DelimitedOut
      include SelectColumns, RecordOut
      def call input, env
        columns = column_args!(input).or_all!.columns
        output = make_output
        output.header.first.meta.type = :String
        input.each do | r |
          output <<
            [
              columns.map{|c| format_value(r[c])} * @field_sep << @record_sep
            ]
        end
        output
      end
    end
  end
end

