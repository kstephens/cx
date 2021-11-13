# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

# :COMMAND:
# HeaderIn:
#   aliases: [-header, -h]
#   synopsis: Interprets first row as a column header.
#   args: []
#   opts:

# :COMMAND:
# HeaderOut:
#   aliases: [header-, h-]
#   synopsis: Emits header as first row.
#   args: []
#   opts:

module CX
  module Xform
    class HeaderIn
      include Xform
      def call input, env
        input.header = Header.new(input.shift.map(&:to_s))
        input
      end
    end
    class HeaderOut
      include Xform
      def call input, env
        output = Table.new([], input.header.dup, input.meta.dup)
        output << input.header.map(&:to_s)
        input.each do | row |
          output << row.dup
        end
        output
      end
    end
  end
end

