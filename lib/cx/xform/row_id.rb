# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

# :COMMAND:
# RowId:
#   aliases:
#   synopsis: Inserts a row id column.
#   args: []
#   opts:
#     name:       'Name of column: default __rowid__.'
#     type:       'Type: "integer" or "uuid".'
#     start:      'Start of integer ids: default 1'

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
              require 'securerandom'
              lambda { || SecureRandom.uuid }
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
          raise ArgumentError, "invalid row id type: #{type.inspect}"
        end

        input.each do | r |
          r[col] = gen.call()
        end

        input
      end
    end
  end
end
