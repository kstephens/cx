# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class Quote
      include Xform
      # :COMMAND:
      # Quote:
      #   name: quote
      #   aliases: q
      #   synopsis: Quote fields that would not be printable..
      #   args: []
      #   opts: {}
      def call input, env
        input.each_row_col_val do | r, c, v |
          if String === v and q = v.inspect and q.gsub(/^"|"$/, '').strip != v
            r[c] = q
          end
        end
        input
      end
    end
  end
end

