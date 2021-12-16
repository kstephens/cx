# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/structured'
require 'edn'

# :COMMAND:
# EdnIn:
#   aliases:
#   synopsis: Parses EDN.
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.edn // -edn // h-'

# :COMMAND:
# EdnOut:
#   aliases:
#   synopsis: Emits EDN.
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.csv // -h // parse // edn-'
#     - 'cx in SOME.csv // -h // parse // h- // edn- --mode=row'


module CX
  module Xform
    class EdnIn
      include StructuredIn
      def parse input, env
        EDN.read(input)
      end
    end

    class EdnOut
      include StructuredOut

      def call input, env
        opts[:seq_delim] ||= '[]'
        opts[:row_delim] ||= (row_mode? ? '[]' :  '{}')
        super
      end

      def line row
        case row
        when Hash
          clj_map(row, row_delim)
        else
          clj_vec(row, row_delim)
        end
      end

      def clj_map row, delim
        delim[0].to_s +
        row.map do| (k, v) |
          key_xform(k) + ' ' << val_xform(v)
        end * ' ' +
        delim[1].to_s
      end

      def clj_vec row, delim
        delim[0].to_s +
        row.map{|v| val_xform(v)} * ' ' +
        delim[1].to_s
      end

      def key_xform k
        case k
        when String, Symbol
          @styles ||= (opts[:key_style] || 'keyword').split(/,/, -1)
          @styles_sel ||= @styles.map {|style| :"key_#{style}!" }
          @styles_sel.inject(k.to_s) {|k, style| send(style, k) }
        else
          val_xform k
        end
      end
      def key_string! k
        case k
        when String, Symbol
          k.to_s.inspect
        else
          k.to_s
        end
      end
      def key_keyword! k
        ":#{k.gsub(/\s+/, '-')}"
      end
      def key_uncamel! k
        k.gsub(/([a-z])([A-Z])/){|| $1 + '-' + $2}
      end
      def key_downcase! k
        k.downcase
      end
      def key_upcase! k
        k.upcase
      end
      def key_dash! k
        k.gsub(/[^-\w+]/, '-')
      end

      def val_xform v
        case v
        when Symbol     then ":#{v}"
        when String     then v.inspect # kinda close?
        when nil        then "nil"
        when Hash       then clj_map(v, @map_delim ||= ['{', '}'])
        when Enumerable then clj_vec(v, @vec_delim ||= ['[', ']'])
        else             v.to_s
        end
      end
    end
  end
end

