# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'terminal-table'

module CX
class TxtOut < Pipe
  include Pipe::Format
  def call input, env
    # NOTE: Terminal::Table cannot stream from Enumerable or to IO.
    header = input.header
    rows   = input.rows

    output = new_table(input)
    title = opts[:title]

    cols = header ? header.cols : [ ]
    
    tt = Terminal::Table.new(rows: rows)

    tt.headings = cols.map(&:to_s) unless cols.empty?
    tt.title = title if title
    tt.style = { :border_top => false,
                 :border_bottom => false,
               }
    cols.each do | c |
      tt.align_column(c.to_i, :right) if c.justify == :right
    end
    
    output << (tt.to_s + "\n")
    env[:content_type] = 'text/plain'
    app.call(output, env)
  end
end

end
