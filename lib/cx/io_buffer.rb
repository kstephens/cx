module CX
  class IOBuffer
    def initialize out, term = "\n"
      if out.respond_to?(:write) # e.g: IO, IOString
        out_io = out
        out = lambda{|x| out_io.write out}
      end
      @out   = out
      @term  = term
      @buf   = String.new
    end
    def call x
      @buf << x.to_str
      while i = @buf.index(@term)
        # pp @buf[r = 0 .. i]
        @out.call @buf[r = 0 .. i]
        @buf[r] = ''
      end
      nil
    end
    alias :<< :call
    alias :write :call
    
    def flush
      @out.call @buf[r = 0 .. -1]
      @buf[r] = ''
      self
    end
  end
end
