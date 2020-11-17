# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/misc' # Sort

module CX
  class RemoveUnused < Pipe
    include Pipe::Process
    def call input, env
      header = input.header!
      unsized_cols = [ ]
      cols = header.to_a.select do | col |
        if col.max_width
          col.max_width > 0
        else
          unsized_cols << col
          true
        end
      end
      unless unsized_cols.empty?
        log.warn "columns have unknown size: did you use 'types' command? : #{unsized_cols.map(&:name)}"
      end
      cut = Cut.new.cut_columns(app, input, env, cols)
    end
  end
end

