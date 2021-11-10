# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class Strip
      include Xform
      # :COMMAND:
      # Strip:
      #   name: strip
      #   aliases: 
      #   synopsis: Strip leading and trailing whitespace.
      #   args: []
      #   opts: {}
      def call input, env
        input.each_row_col_val do | r, c, v |
          if String === v
            r[c] = v.strip
          end
        end
        input
      end
    end
  end
end

