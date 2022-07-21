# frozen_string_literal: true

require 'cx/xform'
require 'cx/help'

# :COMMAND:
# Help:
#   aliases:
#   synopsis: 'Show this documentation.'
#   description: |-
#     Subcommands:
#     * run-examples! - runs all command examples into ex/cmd/.
#     * make-help!    - regenerates this documetation.
#   args: [ 'run-examples!', 'make-help!'  ]
#

module CX
  module Xform
    class Help
      include Xform

      def call input, env
        args = self.args.dup
        case args[0]
        when 'run-examples!'
          CX::Help.new.run_examples!(args[1 .. -1])
          doc = ''
        when 'make-help!'
          doc = CX::Help.new.make_document!.full_document
        else
          doc = CX::Help.new do | help |
            help.opts = opts
            help.search_terms = args
          end.document
        end
        rows = doc.split(/\n/, -1).map{|line| [ line << "\n" ]}
        Table.new(rows, Header.new([:HELP]))
      end
    end
  end
end
