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
#   examples:
#     - 'cx in SOME.csv // -h // uniq d  // h-'
#     - 'cx in SOME.csv // -h // uniq    // h-'

module CX
  module Xform
    class Uniq
      include SelectColumns, Xform
      
      def call input, env
        column_args!(input).or_all!
        columns = column_args.args.map(&:column)
        uniq input, env, columns
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
        output = Table.new(input.header.dup)
        output.header << :COUNT
        found = { }
        counts = Hash.new{|h, k| h[k] = 0}
        input.each do | row |
          k = columns.map{|c| row[c]}
          counts[k] += 1
          found[k] ||= row
        end
        header = output.header
        exlempares.each do | k, r |
          output << (header.map{|c| row[c]} << counts[k])
        end
        output = MetaIn.new.call(output, env)
        output
      end
    end
  end
end

