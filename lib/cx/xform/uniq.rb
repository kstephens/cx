# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/column_args'
require 'cx/compare'
require 'set'

# :COMMAND:
# Uniq:
#   aliases: []
#   synopsis: Emit only rows with uniq columns.
#   args: []
#   opts: {}
#   has_column_args: true
#   examples:
#     - 'cx in SOME.csv // -h // uniq d  // h-'
#     - 'cx in SOME.csv // -h // uniq    // h-'
#     - 'cx in DUPLICATES.csv // -h // uniq   // h-'
#     - 'cx in DUPLICATES.csv // -h // uniq x // h-'
#     - 'cx in DUPLICATES.csv // -h // uniq y // h-'

module CX
  module Xform
    class Uniq
      include SelectColumns, Xform
      
      def call input, env
        column_args!(input).or_all!
        columns = column_args.args.map(&:column)
        if opts[:c] || opts[:count]
          uniq_count input, env, columns
        else
          uniq input, env, columns
        end
      end

      def uniq input, env, columns
        output = input.dup
        output.clear
        seen = Set.new
        input.each do | row |
          k = columns.map{|c| row[c]}
          unless seen.include?(k)
            seen << k
            output << row
          end
        end
        output = MetaIn.new.call(output, env)
        output
      end
    
      def uniq_count input, env, columns
        output = Table.new(nil, input.header.dup)
        output.header << :COUNT
        output.header[:COUNT].meta.type = Integer
        examples = { }
        counts = Hash.new{|h, k| h[k] = 0}
        input.each do | row |
          k = row.vals(columns)
          counts[k] += 1
          examples[k] ||= row.vals(input.header)
        end
        header = output.header
        examples.each do | k, example |
          output << (example << counts[k])
        end
        # output = MetaIn.new.call(output, env)
        output
      end
    end
  end
end

