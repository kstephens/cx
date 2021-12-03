require 'cx'

module CX
  module Debug
    class << self
      attr_accessor :debug
    end
    attr_accessor :debug
    def debug?
      @debug || Debug.debug
    end
  end
end
