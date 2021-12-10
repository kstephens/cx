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

        group_cols = group_ca.map do | ca |
          ca.data[:output_col] = ca.column.dup.clear!
        end
        
        stats_fields = [:count, :sum, :min, :max, :mean, :median, :stddev]
        value_cols = values_ca.flat_map do | ca |
          h = ca.data[:output_cols] = stats_fields.map do | sf |
            c = Column.new(:"#{ca.column.name}_#{sf}")
            c.meta.align = :right
            [ sf, c ]
          end.to_h
          h.values
        end

        header = Header.new(group_cols + value_cols)
        output = Table.new([], header)
        
        # binding.pry
        
        groups.each do | group, rows |
          out_row = output.make_row []
          # pp(group: group)
          # binding.pry

          group_ca.each do | gca |
            out_row[gca.data[:output_col]] = rows.first[gca.column]
          end
          
          values_ca.each do | vca |
            in_col = vca.column
            values = rows.map{|r| r[in_col]}
            stats = vca.data[:stats] =
              ::CX::Stats.new(vca.name, values).complete!
            vca.data[:output_cols].each do | stats_field, out_col |
              out_row[out_col] = stats[stats_field].to_f
            end
          end
          # binding.pry
          output << out_row
        end
        MetaIn.new.call(output, env)
      end
    end
  end
end

