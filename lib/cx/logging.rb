# frozen_string_literal: true

require 'cx'
require 'cx/inspect'
require 'cx/util'
require 'logger'

module CX
  module Logging
    def self.log
      @@log ||= ThreadSafe.new(::Logger.new($stderr))
    end
    
    @@log = nil
    def log
      Logging.log # @_log ||= PrefixedLog.new(self, Logging.log)
    end

    class PrefixedLog < Object
      def initialize cntx, log
        @cntx, @log = cntx, log
      end
      [ :debug, :info, :warn, :error, :fatal ].each do | m |
        define_method(m) do | msg, *args, &blk |
          @log.send(m, "#{prefix} : #{msg}", *args, &blk)
        end
      end
      def prefix ; @cntx.inspect ; end
      def method_missing sel, *args, &blk
        @log.send(sel, *args, &blk)
      end
    end

    #def puts *args
    #  $stderr.puts(*args)
    #  nil
    #end
      
    def pp *args
      log.debug { pps(*args) }
    end
    
    def pps *args
      ::PP.pp(*args, String.new).chomp
    end
    
    def ppss expr
      pps(expr).strip
    end
  end
end
