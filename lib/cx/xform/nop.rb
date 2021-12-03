# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# Nop:
#   aliases: noop
#   synopsis: Does nothing -- output is same as input.
#   args: []
#   opts: {}

module CX
  module Xform
    class Nop
      include Xform
      def call input, env
        input
      end
    end
  end
end

