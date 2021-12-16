require 'open3'
require 'thread'

module CX
  class IOCommand
    attr_accessor :write_fn, :read_fn
    
    def initialize *args
      @write_fn, @read_fn = args
    end
    
    def call command
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
