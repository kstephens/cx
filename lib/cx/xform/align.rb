# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# Align:
#   aliases:
#   synopsis: Aligns fields based on column max_size.
#   args: []
#   opts: {}

module CX
  module Xform
    class Align
      include SelectColumns, Xform

      def call input, env
        set_cols! input.header
        input.each do | row |
          align_row row
        end
        @cols = @c_mw = @c_fmt = nil
        input
      end
      
      def set_cols! cols, min_width = 5
        @cols = cols
        @c_mw = {}
        @cols.each do |c|
          m = c.meta
          @c_mw[c] = 
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
        @cols.map do |c|
          align_col row[c.to_i].to_s, c, fill
        end
      end

      def align_col v, c, fill
        mw = @c_mw[c]
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

