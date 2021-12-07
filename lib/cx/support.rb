require 'cx'
require 'cx/error'
require 'cx/debug'
require 'cx/inspect'
require 'cx/logging'
require 'cx/random'

module CX
  module Support
    include Error::Support, Debug, Inspect, Logging
    def included target
      super
      extend target
    end
  end
end
