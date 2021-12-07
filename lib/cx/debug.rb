require 'cx'

module CX
  module Debug
    class << self
      attr_accessor :debug, :verbose
    end
    attr_accessor :debug, :verbose

    def debug?
      @debug || Debug.debug
    end
    def verbose?
      @verbose || Debug.verbose
    end

    def debug
      if block_given?
        yield if debug?
      else
        @debug
      end
    end

    def verbose
      if block_given?
        yield if verbose?
      else
        @verbose
      end
    end
  end
end
