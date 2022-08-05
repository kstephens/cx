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
#   arguments: []
#   options: {}

# :COMMAND:
# TsvOut:
#   aliases:
#   synopsis: Generates TSV lines.
#   suffixes: [ .tsv ]
#   inverse: [ '-tsv' ]
#   arguments: []
#   options: {}
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
      def content_type ; 'text/tab-separated-values' ; end # # according to RFC 4180.
    end
  end
end

