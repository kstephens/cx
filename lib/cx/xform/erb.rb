# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'

# :COMMAND:
# ErbOut:
#   aliases: [ erb ]
#   synopsis: Evaluates ERB in the context of input table.
#   args: [template.erb]
#   opts:
#     erb-options=: See ERB doc trim_mode.
#   examples:
#     - 'cx in SOME.csv // -csv // -h // erb SOME.erb'

module CX
  module Xform
    class ErbOut
      include RecordOutBase, Xform
      
      def call input, env
        erb_file = args[0] or raise_ "Missing ERB filename"
        
        template = File.read(erb_file) or raise_ "Cannot read #{erb_file.inspect}"
        @erb = ERB.new(template,
          trim_mode: opts.fetch(:erb_options, "-"),
          # eoutvar: 'self',
        )
        @erb.filename = erb_file
        template = nil

        @output = make_output
        data = evaluate!(input, env)
        data = data.split("\n", -1)
        data.pop if data[-1] == '' # 
        data.each do | line |
          @output << [ line << "\n" ]
        end

        @erb = data = nil
        @output.tap{ || @output = nil }
      end

      def evaluate! input, env
        @erb.result(binding)
      end
    end
  end
end

