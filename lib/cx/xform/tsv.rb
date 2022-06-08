# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/csv'

# :COMMAND:
# TsvIn:
#   aliases:
#   synopsis: Parses TSV lines.
#   suffixes: [ .tsv ]
#   inverse: [ 'tsv-' ]
#   args: []
#   opts: {}

# :COMMAND:
# TsvOut:
#   aliases:
#   synopsis: Generates TSV lines.
#   suffixes: [ .tsv ]
#   inverse: [ '-tsv' ]
#   args: []
#   opts: {}
#   examples:
#     - cx in SOME.csv // tsv-

module CX
  module Xform
    class TsvIn < CsvIn
      def initialize!
        opts[:separator] = "\x09"
        super
      end
    end
    
    class TsvOut < CsvOut
      def initialize!
        opts[:separator] = "\x09"
        super
      end
    end
  end
end

