# frozen_string_literal: true

require 'cx/xform'
require 'cx/io_command'

# :COMMAND:
# Cmd:
#   aliases: [ command, / ]
#   synopsis: Pipe through an external command.
#   args: [ command, args... ]

module CX
  module Xform
    class Cmd
      include RecordOutBase, Xform
      attr_accessor :command, :write_fn, :read_fn

      def inspect_content modes
        @command.inspect
      end
  
      def call input, env
        @column_offset  = (opts[:column_offset]  || 1).to_i

        @command ||= args
        @command = replace_column_arguments(input,  @command)
        
        @output = make_output

        IOCommand.new(
          lambda do | io |
            input.each do | row |
              io.write(row.to_a.map(&:to_s) * '')
            end
          end,
          lambda do | io |
            until io.eof?
              @output << [ io.readline ] 
            end
          end
        ).call(command)
        
        @output
      end

      def replace_column_arguments input, command
        header = input.header
        rx = Regexp.new("%(" + header.map{|c| Regexp.quote(c.to_s)} * '|' + ")%")
        command.map do | arg |
          arg.gsub(rx){|m| header[$1].to_i + @column_offset}
        end
      end
      
    end
  end
end
