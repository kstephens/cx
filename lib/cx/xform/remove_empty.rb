# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/strip'
require 'cx/xform/empty_to_null'
require 'cx/xform/meta'

# :COMMAND:
# RemoveEmpty:
#   name: remove-empty
#   aliases: [compact]
#   synopsis: Empty columns and rows are removed.
#   args: []
#   has_column_args: true
#   opts: {}

module CX
  module Xform
    class RemoveEmpty
      include SelectColumns, Xform
      def call input, env
        input = EmptyToNull.new.call(input, env)
        input = MetaIn.new.call(input, env)
        columns = column_args!(input).or_all!.columns
        header = Header.new
        columns.each do | col |
          if col.meta.nulls + col.meta.blanks < input.size
            header << col
          end
        end
        output = Table.new(nil, header)
        input.each do | in_row |
          out_row = header.map{|c| in_row[c.to_sym] }
          pp(out_row: out_row)
          unless out_row.all?(&:nil?)
            output << out_row
          end
        end
        output = MetaIn.new.call(output, env)
        output
      end
    end
  end
end

