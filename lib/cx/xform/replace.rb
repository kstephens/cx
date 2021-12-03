# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/column_args'

# :COMMAND:
# Replace:
#   aliases: sub
#   synopsis: Replace by regex.
#   args: []
#   opts:

module CX
  module Xform
    class Replace
      include Xform
      def call input, env
        @cleared = Set.new
        col_args = ColumnArgs.new.parse!(args).bind!(input.header)
        fns = col_args.map{|arg| replace_fn input.header, arg}
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
      rx = Regexp.new(search)
      lambda do | row |
        old_v = row[c].to_s
        new_v = old_v.sub(rx, replace)
        if old_v != new_v
          unless @cleared.include?(c)
            @cleared << c
            c.meta.clear!
            c.meta.type = :String
            c.meta.type_inferred = nil
          end
          row[c] = new_v
        end
      end
    end
  end
end

