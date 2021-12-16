# frozen_string_literal: true

require 'cx/xform'
require 'open3'
require 'thread'

# :COMMAND:
# Cmd:
#   aliases: [ command, / ]
#   synopsis: Pipe through an external command.
#   args: [ command, args... ]

module CX
  module Xform
    class Cmd
      include RecordOut, Xform
      attr_accessor :command, :write_fn, :read_fn

      def inspect_content modes
        @command.inspect
      end
  
      def call input, env
        @column_offset  = (opts[:column_offset]  || 1).to_i

        @command ||= args
        @command = replace_column_arguments(input,  @command)
        
        @output = make_output
        
        @write_fn = lambda do | io |
          input.each do | row |
            io.write(row.to_a.map(&:to_s) * '')
          end
        end

        @read_fn = lambda do | io |
          until io.eof?
            @output << [ io.readline ] 
          end
        end
        
        run! command
        
        @output
      end

      def replace_column_arguments input, command
        header = input.header
        rx = Regexp.new("%(" + header.map{|c| Regexp.quote(c.to_s)} * '|' + ")%")
        command.map do | arg |
          arg.gsub(rx){|m| header[$1].to_i + @column_offset}
        end
      end
      
      def run! command
        stdin = stdout = wait_thr = wt = rt = nil
        reraise do
          stdin, stdout, wait_thr = Open3.popen2(*command)
          wt = with_io(stdin,  @write_fn, "stdin")
          rt = with_io(stdout, @read_fn,  "stdout")
          wt.join
          rt.join
          wait_thr.value # Fail on command exit code ???
        end
      ensure
        stdin.close  rescue nil
        stdout.close rescue nil
        wt.join      rescue nil
        rt.join      rescue nil
        wt.kill      rescue nil
        rt.kill      rescue nil
        unless $!
          raise_ wt[:name], wt[:exc] if wt && wt[:exc]
          raise_ rt[:name], rt[:exc] if rt && rt[:exc]
        end
      end

      def with_io io, fn, kind
        Thread.new do
          thr = Thread.current
          thr[:name] = "#{self.class} #{kind}"
          begin
            thr[:result] = fn.call(io)
          rescue
            thr[:exc] = $!
            log.error "#{kind} : #{$!}"
          ensure
            io.close
          end
        end
      end
    end
  end
end
