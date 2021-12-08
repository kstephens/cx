# frozen_string_literal: true

require 'cx/xform'
require 'cx/help'

# :COMMAND:
# Help:
#   aliases:
#   synopsis: 'Show this documentation.'
#   description: |-
#     Subcommands:
#     * show         - this documentation (default).
#     * run-examples - runs all command examples into ex/cmd/.
#     * make-help    - regenerates this documetation.
#   args: [ 'show', 'run-examples', 'make-help'  ]
#

module CX
  module Xform
    class Help
      include Xform

      def call input, env
        help = CX::Help.new
        doc = ''
        args.push 'show' if args.empty?
        args.each do | arg |
          case arg
          when 'run-examples'
            help.run_examples!
          when 'make-help'
            help.make_document!
          when 'show'
            doc = help.document
          else
            raise "Unknown argument #{arg.inspect}"
          end
        end
        rows = doc.split(/\n/, -1).map{|line| [ line << "\n" ]}
        Table.new(rows, Header.new([:HELP]))
      end
    end
  end
end
