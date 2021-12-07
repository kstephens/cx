# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/command/types'

module CX
  class Columns < Pipe
  include Pipe::Diagnostic, Pipe::NeedsHeader
  def call input, env
    col_opts = Header.parse_column_args(args)
    header = input.header ||= Header.new
    col_opts.each do | (name, opts) |
      col = header[name] || header.add_col!(name)
      col.opts = opts
    end
    app.call(input, env)
  end
end

class ColumnsOut < Pipe
  include Pipe::Diagnostic, Pipe::NeedsHeader
  
  def call input, env
    cols = [:name, :ind, :type, :min_width, :max_width, :justify, :n_values, :n_blanks, :n_nulls, :min, :max]
    header = Header.new(cols)
    output = new_table(Table, header)
    output.rows = input.header.map do | c |
      cols.map{|sel| c.send(sel)}
    end
    CX::Types.new(app, [], {}).call(output, env)
  end
end

end
