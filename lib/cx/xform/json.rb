# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/structured'
require 'json'

# :COMMAND:
# JsonIn:
#   aliases:
#   synopsis: Parses JSON.
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.json // -json // h-'

# :COMMAND:
# JsonOut:
#   aliases:
#   synopsis: Emits JSON.
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.csv // -h // parse // json-'


module CX
  module Xform
    class JsonIn
      include StructuredIn
      def parse input, env
        JSON.load(input)
      end
    end

    class JsonOut
      include StructuredOut

      def initialize!
        super
      end
       
      def call input, env
        opts[:seq_delim] ||= '[]'
        opts[:row_delim] ||= (row_mode? ? '[]' :  '{}')
        super
      end

      def line row
        # TODO: handle alternate row_delim
        JSON.dump(row)
      end
  
      def row_sep ; super || ',' ; end

      def content_type ; 'application/json' ; end
    end
  end
end

