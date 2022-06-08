module CX
  class Measured
    def self.proxy *args
      Measured.new(*args).proxy
    end

    def self.measure! opts = nil
      inst = Measured.new(nil, opts)
      result = inst.measure! nil do
        yield
      end
      inst.print
      result
    end

    def self.print! *args
      inst = Measured.new(*args)
      result = yield inst.proxy
      inst.print
      result
    end
  
    class Proxy < ::BasicObject
      attr_accessor :__measurements__
      def method_missing sel, *args, &blk
        @__measurements__.forward! sel, args, blk
      end
      def respond_to? sel
        @__measurements__.target.respond_to?(sel)
      end
    end

    attr_reader :target, :opts, :name, :measurements
    
    def initialize target, opts = nil
      @target = target
      @opts = (opts || {}).dup
      @name = @opts[:name] || target.class.name.to_sym rescue nil
      @measurements = Hash.new do | h, tag |
        h[tag] = Measurement.new
      end
      @measurements[nil] # "all" slot first
    end

    def proxy
      proxy = Proxy.allocate
      proxy.__measurements__ = self
      proxy
    end
    
    def forward! sel, args, blk
      measure! sel do
        @target.__send__(sel, *args, &blk)
      end
    end

    def measure! tag
      # raise unless block_given?
      t0 = Time.now
      begin
        yield
      ensure
        dt = Time.now - t0
        @measurements[nil].dt! dt
        @measurements[tag].dt! dt unless tag.nil?
      end
    end

    def to_h
      {
        name: name,
        # opts: opts,
        measurements: measurements.to_h,
      }
    end
    
    def print io = $stderr
      PP.pp(to_h, io)
      nil
    end
    
    class Measurement < Struct.new(:n, :total_sec, :min_sec, :avg_sec, :max_sec)
      def initialize
        super(0, 0.0, 0.0, 0.0, 0.0)
      end
      def dt! dt
        self.n          += 1
        self.total_sec  += dt
        self.avg_sec     = total_sec / n
        self.min_sec     = dt if dt < min_sec
        self.max_sec     = dt if dt > max_sec
        self
      end
    end
  end
end
