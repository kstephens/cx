# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/meta_in'

# :COMMAND:
# MetaTable:
#   aliases: meta-, meta, columns, columns-
#   synopsis: Generate a table of table metadata.
#   args: []
#   opts: {}

module CX
  module Xform
    class MetaTable
      include Xform
      def call input, env
        output = input.header.meta.table
        # output << input.header.meta.to_h
        input.header.each do | c |
          output << c.meta.to_h
        end
        MetaIn.new.call(output, env)
      end
    end
  end
end

