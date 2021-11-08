# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class MarkdownOut < Pipe
  include Pipe::Format
  def call input, env
    header = input.header

    title = opts[:title]
    pp(self: self, rows: rows, header: header) if debug?

    format_row = lambda do | row |
      '| ' + (row * ' | ') + " |\n" 
    end
    if header
      c_mw = header.map{|c| [c.max_width || 0, c.name.to_s.size, 4].max }
      format_row_ = format_row
      format_row = lambda do | row, fill = nil |
        format_row_[
          header.map.with_index do |c, i|
            v = row[c.to_i].to_s
            mw = c_mw[i]
            case fill
            when String
              v = fill * mw
              v[-1] = ':' if c.justify == :right
            when :header
              mw = - mw
              v = "%#{mw}s" % v
            else
              mw = c.justify == :right ? mw : - mw
              v = "%#{mw}s" % v
            end
            v
          end
        ]
      end
    end
    input.map! do | row |
      format_row[row]
    end
    if header
      input.unshift format_row[header.map{|_| '---'}, '-']
      input.unshift format_row[header.map(&:to_s), :header]
    end
    env[:content_type] = 'text/markdown' # 2016 RFC7763 at IETF
    app.call(input, env)
  end
end

end

