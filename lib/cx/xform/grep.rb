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
#   has_column_args: true
#   examples:
#     - 'cx in SOME.csv // -h // grep d:f'
#     - 'cx in SOME.csv // -h // grep d:a'
#     - 'cx in SOME.csv // -h // grep d:^a'
#     - 'cx in SOME.csv // -h // grep "d:!;f"'

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
    
    def rx_pred ca
      c = ca.column or raise_ ArgumentError, ca.inspect
      rx = Regexp.new(ca.args[-1] || '')
      if ca.opts[:negate] || ca.opts[:order] == -1
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

