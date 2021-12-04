# frozen_string_literal: true

require 'cx/xform'

# :COMMAND:
# Cat:
#   aliases:
#   synopsis: 'Concatenates rows from multiple pipelines.'
#   args: [ pipelines, ... ]

module CX
  module Xform
    class Cat
      include Xform
      
      def call input, env
        input_xforms = args
        input_xforms.each do | x |
          raise_ "expected xform : #{x.inspect}" unless Xform::Pipeline  === x
          ## FIXME:!!!
          # x.default_format!(env[:main][:defaults])
        end

        output = input
        output_header = output.header
        
        input_xforms.each do | input_xform |

          input_table = input_xform.call(Table.new, env)
          input_header = input_table.header
          
          # Add missing columns to output:
          input_header.each do | c |
            unless output_header[c.to_sym]
              output_header.add_column!(c.dup.clear!)
            end
          end

          # Scan each input table for output columns:
          input_table.each do | row_in |
            output << output_header.map do | c |
              c = c.to_sym
              row_in[c] if input_header[c]
            end
          end
        end
        
        output
      end

      def inspect_content modes
        "#{args.inspect}"
      end
    end
  end
end
