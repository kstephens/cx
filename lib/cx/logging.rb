# frozen_string_literal: true

require 'cx'
require 'cx/inspect'
require 'cx/util'
require 'logger'

module CX
  module Logging
    def self.log
      @@log ||=
        ::Logger.new($stderr)
        .tap do |log|
          log.formatter = Proc.new do | severity, datetime, progname, msg |
            "# cx : %-6s : %s\n" % [ severity, msg ]
          end
          log.extend Delimited
        end
    end

    module Delimited
      VAR = :"#{self}.level"
      def delimited msg, level = :info
        thr = Thread.current
        thr[VAR] ||= 0
        depth, thr[VAR] = thr[VAR], thr[VAR] + 1
        indent = '  ' * depth
        begin
          send(level) do
            indent.dup << "{ " << msg
          end
          yield
        ensure
          thr[VAR] = depth
          send(level) do
            indent.dup << "} " << msg
          end
        end
      end
    end
    
    @@log = nil
    def log
      Logging.log
    end

    def pp *args
      log.debug { pps(*args) }
    end

    def pp_info *args
      log.info { pps(*args) }
    end

    def pps *args
      ::PP.pp(*args, String.new).chomp
    end
    
    def ppss expr
      pps(expr).strip
    end
    
    def with_newlines s
      s = s.to_s
      if s.index("\n")
        s = "::::\n#{s}::::"
      end
      s
    end
  end
end
