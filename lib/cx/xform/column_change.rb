# frozen_string_literal: true

require 'cx'
require 'cx/xform'

module CX
  module Xform
    # Tracks if a value changed and will yield once for each column.
    module ColumnChange
      def change_start!
        @column_changed = Set.new
      end
      
      def change_maybe! r, c, old_v, new_v
        unless new_v.class == old_v.class && new_v == old_v && 
          r[c] = new_v
          unless @column_changed.include?(c)
            @column_changed << c
            yield if block_given?
          end
        end
      end
    end
  end
end

