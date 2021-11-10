# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class Align
      include Xform
      # :COMMAND:
      # Align:
      #   name: align
      #   aliases: o
      #   synopsis: Aligns fields based on column max_size.
      #   args: []
      #   opts: {}
      def call input, env
        header! input.header
        input.each do | row |
          align_row row
        end
        input
      end
      
      def header! header, min_width = 5
        @header = header
        @c_mw = header.map do |c|
          m = c.meta
          [
            m.max_size || 0,
            c.name.size,
            min_width
          ].max
        end
        @c_fmt = Hash.new{|h,i| h[i] = "%#{i}s"}
        self
      end

      def align_row row, fill = nil
        @header.map do |c|
          align_col row[c.to_i].to_s, c, fill
        end
      end

      def align_col v, c, fill
        mw = @c_mw[c.to_i]
        case fill
        when :header
          mw = - mw
          v = @c_fmt[mw] % v
        when String
          center = (align = c.meta.align_) == :center
          v = fill * mw
          v[0]  = ':' if center || align == :left
          v[-1] = ':' if center || align == :right
        else
          mw = c.meta.align_ == :right ? mw : - mw
          v = @c_fmt[mw] % v
        end
        v
      end
    end
  end
end

