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
      include Xform
      def call input, env
        input.each_row_col_val do | r, c, v |
          if String === v && v.empty?
            r[c] = nil
          end
        end
        input
      end
    end
  end
end

