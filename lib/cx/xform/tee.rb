# frozen_string_literal: true

require 'cx/xform'

# :COMMAND:
# Tee:
#   aliases: t
#   synopsis: 'Send input to multiple output pipelines.'
#   args: [ pipelines, ... ]

module CX
  module Xform
    class Tee
      include Xform
      
      def call input, env
        outputs = args
        outputs.each do | o |
          raise_ "expected xform : #{o.inspect}" unless Xform === o
        end
        
        outputs.each do | output |
          # Pipelines often edit tables in-place.
          # Input must be deep copied for each output.
          output.call(input.dup, env)
        end
        
        input
      end

      def inspect_content modes
        "#{args.inspect}"
      end
    end
  end
end
