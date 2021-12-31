# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# Strip:
#   aliases: trim
#   synopsis: Strip leading and trailing whitespace.
#   args: []
#   opts: {}

module CX
  module Xform
    class Strip
      include SelectColumns, Xform
      def call input, env
        columns = column_args!(input).or_all!.columns
        input.each_columns columns do | r, c, v |
          if String === v
            r[c] = v.strip
          end
        end
        input = MetaIn.new.call(input, env)
        input
      end
    end
  end
end

