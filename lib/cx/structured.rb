# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'json'

module CX
  class StructuredIn < Pipe
    include Pipe::Parse
    
    def call input, env
      cols = { }
      inds = Hash.new{|h,k| h[k] = (0..k).to_a}
      # EXPENSIVE: See deleted RowReader for a broken alternative
      input = input.to_a * ''
      rows = parse(input, env).map do | row |
        cols.update(Hash[row.keys.zip(inds[row.size])])
        row.values_at(*cols.keys)
      end
      input = nil
      header = Header.new(cols.keys)
      width = cols.keys.size
      rows.each do | row |
        row[width - 1] = nil unless row.size == width
      end
      output = new_table(Table, header)
      output.rows = rows
      app.call(output, env)
    end
  end

class StructuredOut < Pipe
  include Pipe::Format
  def init_more!
    super
    @seq_delim = '[]'
    @row_delim = '{}'
    @row_sep   = ','
  end
  def call input, env
    output = new_table(input)
    row_delim = self.row_delim
    array_mode = opts[:mode] == 'row'
    row_sep = cols = nil
    if input.header
      cols = input.header.cols
      have_types = cols.any?(&:type)
      col_names = cols.map(&:to_sym)
    else
      array_mode = true
    end
    output << seq_delim[0]
    input.each_shift do | row |
      output << row_sep.to_s << "\n"
      data = if array_mode 
               row
             else
               if have_types
                 row = cols.map do |c|
                   v = row[c.to_i];
                   v = Typing.coerce(v, c.type) if c.type
                   v
                 end
               end
               Hash[col_names.zip(row)]
             end
      pp(row: row, data: data) if debug?
      output << line(data, row_delim)
      row_sep = self.row_sep
    end
    output << ("\n" + seq_delim[1] + "\n")
    if x = content_type
      env[:content_type] = x
    end
    app.call(output, env)
  end
  def content_type ; nil ; end
  def line row
    raise
  end
  def seq_delim
    @seq_delim ||= make_delim opts[:seq_delim]
  end
  def row_delim
    @row_delim ||= make_delim opts[:row_delim]
  end
  def make_delim cfg
    cfg ? cfg.to_s.gsub(/\s/, '').split('', 2).map(&:to_s) : [nil, nil]
  end
  def row_sep
    opts[:row_sep]
  end
end


end
