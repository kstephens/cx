# frozen_string_literal: true

require 'cx/xform'

# :COMMAND:
# Cat:
#   aliases: [ ]
#   synopsis: 'Concatenates rows from multiple pipelines.  Columns are shared.'
#   args: [ ]
#   options: { }
#   examples:
#     - 'cx in OTHER.csv // -h // cat {{ in DUPLICATES.csv // -h }} // h-'

module CX
  module Xform
    class Cat
      include PipelineArgs, Xform
      
      def call input, env
        input_xforms = args.select{|x| Xform::Pipeline === x}
        input_xforms.each do | x |
          x.default_input_format!(env[:main][:defaults][:input_format])
        end
        if input_xforms.empty?
          log.warn "cat: no inputs"
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
