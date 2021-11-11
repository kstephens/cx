module CX
  class IOBuffer
    def initialize out, term = "\n"
      @out   = out
      @term  = term
      @buf   = String.new
    end
    def call x
      @buf << x.to_str
      while i = @buf.index(@term)
        pp @buf[r = 0 .. i]
        @out.call @buf[r = 0 .. i]
        @buf[r] = ''
      end
    end
    alias :<< :call
    alias :write :call
  end
end
