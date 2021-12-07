# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# Align:
#   aliases:
#   synopsis: Aligns fields based on column max_size and alignment.
#   args: []
#   opts:
#   examples:
#     - 'cx in SOME.csv // -h // parse // align'

module CX
  module Xform
    class Align
      include SelectColumns, Xform

      def call input, env
        set_cols! column_args!(input).or_all!.columns
        input.map_columns!(@cols) do | r, c, v |
          align_col c, v, nil
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

      def align_row row, fill
        @cols.map.with_index do |c, i|
          align_col c, row[i], fill
        end
      end

      def align_col c, v, fill
        old_v = v
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
        # pp(c: c, old_v: old_v, v: v, fill: fill)
        # binding.pry
        v
      end

      def center v, width, pad = ' '
        v = v.to_s
        w = width - v.size
        w = 0 if w < 0
        l = w / 2
        r = width - l - v.size
        (pad * l) + v + (pad * r)
      end
    end
  end
end

