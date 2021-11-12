# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/column_args'

# :COMMAND:
# HeaderOut:
#   name: header-out
#   aliases: header-, h-
#   synopsis: Emits a row header.
#   args: []
#   opts:
# HeaderOut:
#   name: header-in
#   aliases: -header, -h
#   synopsis: Interprets first row as a column header.
#   args: []
#   opts:

module CX
  module Xform
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

