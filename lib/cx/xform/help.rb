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
        Table.new([[doc]], Header.new([:HELP]))
      end
    end
  end
end
