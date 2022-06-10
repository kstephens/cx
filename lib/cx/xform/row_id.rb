# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/random'

# :COMMAND:
# RowId:
#   aliases:
#   synopsis: Inserts a row id column.
#   args: []
#   opts:
#     name=:       'Name of id column.  Default: "__rowid__".'
#     type=:       'Type: "integer" or "uuid".  Default: "integer".'
#     start=:      'Start of integer ids.  Default: 1'
#   examples:
#     - 'cx in SOME.csv // -h // row-id --start=100 // h-'
#     - 'cx in SOME.csv // -h // row-id --name=id // h-'
#     - 'cx in SOME.csv // -h // row-id --type=uuid --name=uuid // h-'

module CX
  module Xform
    class RowId
      include Xform
      attr_accessor :uuid_generator
      
      def call input, env
        col_name = (opts[:name] || :__rowid__).to_sym
        type     = (opts[:type] || "integer").to_s

        col = Column.new(col_name)
        col.order = -999
        input.header << col
        input.header.compact!

        case type
        when 'uuid'
          gen = @uuid_generator ||
            begin
              lambda { || CX::Random.uuid }
            end
          col.meta.type = ::String
          col.meta.min_size = col.meta.max_size = gen.call.size
        when 'integer'
          i = (opts[:start] || 1).to_i
          i -= 1
          # + 1 to handle negative start
          max_i = i + input.rows.size
          gen = lambda { || i += 1 }
          col.meta.type = ::Integer
          col.meta.min_value = i
          col.meta.max_value = max_i
          col.meta.min_size  = i.to_s.size
          col.meta.max_size  = (Math.log10(max_i) + 1).to_i + 1 + 1
        else
          raise_ ArgumentError, "invalid row id type: #{type.inspect}"
        end

        input.each do | r |
          r[col] = gen.call()
        end

        input
      end
    end
  end
end
