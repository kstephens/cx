# frozen_string_literal: true

require 'cx'
require 'cx/error'
require 'open3'
require 'thread'

module CX
  class IOCommand
    include Error::Support
    
    attr_accessor :stdin_fn, :stdout_fn
    
    def initialize *args
      @stdin_fn, @stdout_fn = args
    end
    
    def call command
      stdin = stdout = wait_thr = wt = rt = nil
      reraise do
        stdin, stdout, wait_thr = Open3.popen2(*command)
        wt = io_thread stdin,   @stdin_fn,   "stdin"
        rt = io_thread stdout,  @stdout_fn,  "stdout"
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

    def io_thread io, fn, kind
      Thread.new do
        thr = Thread.current
        thr[:name] = "#{kind}"
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
