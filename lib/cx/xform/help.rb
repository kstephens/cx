# frozen_string_literal: true

require 'cx/xform'
require 'cx/help'

# :COMMAND:
# Help:
#   aliases:
#   synopsis: 'This documentation.'
#   args: [ command ]

module CX
  module Xform
    class Help
      include Xform

      def call input, env
        help = CX::Help.new
        help.run_examples!   if opts[:run_examples]
        help.make_document!  if opts[:make_help]
        doc = help.document
        Table.new([[doc]], Header.new([:HELP]))
      end
    end
  end
end
