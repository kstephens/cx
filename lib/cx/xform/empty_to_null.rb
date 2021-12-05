# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# EmptyToNull:
#   name: empty-null
#   aliases: 
#   synopsis: Empty fields are converted to NULL.
#   args: []
#   opts: {}

module CX
  module Xform
    class EmptyToNull
      include SelectColumns, Xform
      def call input, env
        columns = column_args!(input).or_all!.columns
        input.each_columns columns do | r, c, v |
          if String === v && v.empty?
            r[c] = nil
          end
        end
        input
      end
    end
  end
end

