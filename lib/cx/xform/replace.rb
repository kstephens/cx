# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/column_args'

# :COMMAND:
# Replace:
#   aliases: g
#   synopsis: Replace by regex.
#   args: []
#   opts:

module CX
  module Xform
    class Replace
      include Xform
      def call input, env
        col_args = ColumnArgs.new.parse!(args).bind!(input.header)
        fns = col_args.map{|arg| replace_fn input.header, arg}
        pp(col_args: col_args.columns)
        # binding.pry
        input.select! do | row |
          fns.each {|f| f.call(row) }
        end
        input
      end
    end
    
    def replace_fn header, col_arg
      search  = col_arg.args[0]
      replace = col_arg.args[1] || ''
      c = col_arg.column or raise ArgumentError, c.inspect
      c.meta.type = nil
      c.meta.type_inferred = :String
      rx = Regexp.new(search)
      pp(rx: rx.inspect, replace: replace)
      lambda do | row |
        row[c] = row[c].to_s.sub(rx, replace)
      end
    end
  end
end

