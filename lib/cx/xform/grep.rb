# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/column_args'

# :COMMAND:
# Grep:
#   aliases: g
#   synopsis: Filters by regex.
#   args: []
#   opts:

module CX
  module Xform
    class Grep
      include SelectColumns, Xform
      
      def call input, env
        preds = column_args!(input).map{|arg| rx_pred arg}
        input.select! do | row |
          preds.all? {|p| p.call(row) }
        end
        input
      end
    end
    
    def rx_pred arg
      c = arg.column or raise ArgumentError, c.inspect
      rx = Regexp.new(arg.args[-1] || '')
      if arg.opts[:negate]
        lambda do | row |
          ! rx.match?(row[c].to_s)
        end
      else
        lambda do | row |
          rx.match?(row[c].to_s)
        end
      end
    end
    
  end
end

