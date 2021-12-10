# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/column_args'
require 'cx/compare'

# :COMMAND:
# Stats:
#   aliases: [ ]
#   synopsis: Collect stats of a group of columns.
#   args: []
#   opts: {}
#   examples:
#     - 'cx in stats-data.csv // -h // parse // stats salary // md'
#     - 'cx in stats-data.csv // -h // parse // stats dept:g salary // md'
#     - 'cx in stats-data.csv // -h // parse // stats job:g salary // md'
#     - 'cx in stats-data.csv // -h // parse // stats dept:g job:g salary // md'

module CX  
  module Xform
    class Stats
      include SelectColumns, Xform
      
      def call input, env
        column_args!(input)
        group_ca, values_ca = column_args.partition{|ca| (ca.args.first || '') =~ /^g/i}

        groups = input.rows.group_by do | r |
          group_ca.map{|ca| r[ca.column]}
        end

        stats_fields = [:count, :sum, :min, :max, :mean, :median, :stddev]

        header = [ ]
        group_cols = group_ca.map do | ca |
          header << (out_col = ca.column.dup.clear!)
          [ ca.column, out_col ]
        end
        value_cols = values_ca.map do | ca |
          [ ca.column,
            stats_fields.map { | sf |
              out_col = Column.new(:"#{ca.column.name}_#{sf}").
                tap{|c| c.meta.align = :right}
              header << out_col
              [ out_col,  sf ]
            } ]
        end

        header = Header.new(header)
        output = Table.new([], header)
        
        groups.each do | group, rows |
          out_row = output.make_row []

          group_cols.each do | (in_col, out_col) |
            out_row[out_col] = rows.first[in_col]
          end
          
          value_cols.each do | (in_col, out_cols) |
            values = rows.map{|r| r[in_col]}
            stats =  ::CX::Stats.new(in_col.name, values).complete!
            out_cols.each do | (out_col, stats_field) |
              out_row[out_col] = stats[stats_field].to_f
            end
          end
          output << out_row
        end
        MetaIn.new.call(output, env)
      end
    end
  end
end

