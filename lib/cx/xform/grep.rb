# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/column_args'

module CX
  module Xform
    class Grep
      include Xform
      # :COMMAND:
      # Grep:
      #   name: grep
      #   aliases:
      #   synopsis: Filters by regex
      #   args: []
      #   opts:
      def call input, env
        col_args = ColumnArgs.new.parse!(args).bind!(input.header)
        # pp(col_args: col_args)
        preds = col_args.map{|arg| rx_pred arg}
        pred = lambda do | row |
          preds.all? do | p |
            p.call(row)
          end
        end
        input.select!(&pred)
        input
      end
    end
    
    def rx_pred arg
      c = arg.column or raise ArgumentError, c.inspect
      rx = Regexp.new(arg.args[-1] || '')
      if arg.opts[:negate]
        lambda do | row |
          rx !~ row[c]
        end
      else
        lambda do | row |
          rx =~ row[c]
        end
      end
    end
    
  end
end

