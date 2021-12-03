# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

# :COMMAND:
# Coerce:
#   aliases: 
#   synopsis: Coerce columns by inferred types.
#   args: []
#   opts: {}

module CX
  module Xform
    class Coerce
      include Xform
      def call input, env
        colargs = ColumnArgs.new.parse!(args).bind!(input.header)
        pp(colargs: colargs)
        input.each do | r |
          r.header.each do | c |
            v = r[c]
            new_v = (c.meta.type_object.coerce(v) rescue nil)
            new_v = c.meta.type_object.coerce(v)
            pp(c: c, type: c.meta.type_, v: v, new_v: new_v) if new_v.class != v.class
            r[c] = new_v if new_v
          end
        end
        input
      end
    end
  end
end

