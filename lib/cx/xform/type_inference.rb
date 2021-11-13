# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/type'

# :COMMAND:
# TypeInference:
#   name: types
#   aliases:
#   synopsis: Infer types from field strings.
#   args: []
#   opts: {}

module CX
  module Xform
    class TypeInference
      include Xform

      def initialize!
        @parse_string = true
      end

      def call input, env
        input.each_row_col_val do | r, c, v |
          vc, vt = infer_type(r, c, v)
          m = c.meta
          m.type_inferred = gcd_ignore_nil(m.type_inferred, vt)
        end
        input
      end

      def infer_type r, c, v
        vc = v
        case
        when v.nil?
          vt = nil
        when ! (vc = Type.try_parse!(v)).nil?
          vt = vc.class
        else
          vt = v.class
        end
        [vc, vt]
      end

      def infer_string_value v, c
        case v
        when String
          formatter.parse(v, c.format)
        else
          v
        end
      end

      def gcd_ignore_nil t1, t2, ignore = nil
        case
        when t1.nil? || t1 == NilClass
          t2
        when t2.nil? || t2 == NilClass
          t1
        else
          gcd(t1, t2, ignore)
        end
      end

      def gcd t1, t2, ignore = nil
        TYPE_LCM[[t1, t2, ignore]] ||=
          begin
            _ignore = (ignore || EMPTY_Array) + IGNORE
            ((t1.ancestors - _ignore) & (t2.ancestors - _ignore))
              .reject{|m| m.class == Module}
              .sort
              .first
          end
      end

      TYPE_LCM = { }
      EMPTY_Array = [].freeze
      IGNORE = [ NilClass ]
    end
  end
end

