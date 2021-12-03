# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/column_args'

# :COMMAND:
# Quote:
#   aliases: q
#   synopsis: Quote fields that would not be printable.
#   args: []
#   opts: {}

module CX
  module Xform
    class Quote
      include SelectColumns, Xform
      
      def call input, env
        columns = column_args!(input).or_all!.columns
        
        input.each do | r |
          columns.each do | c |
            v = r[c]
            if String === v and q = v.inspect and q.gsub(/^"|"$/, '').strip != v
              r[c] = q
            end
          end
        end
        input
      end
    end
  end
end

