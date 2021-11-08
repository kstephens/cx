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
  def call input, env
    output = new_table(input)
    row_sep = nil
    output << seq_delim[0].to_s
    fn = row_fn input
    input.each_shift do | row |
      output << row_sep.to_s << newline
      output << line(fn.call(row))
      row_sep = self.row_sep
    end
    output << (newline + seq_delim[1].to_s + newline)
    if x = content_type
      env[:content_type] = x
    end
    app.call(output, env)
  end

  def row_mode? ; opts[:mode] == 'row' ; end

  def newline
    "\n"
  end
  
  def row_fn input
    fn = Proc.new{|row| row}
    if input.header
      cols = input.header.cols
      col_names  = cols.map(&:to_sym)
      unless row_mode?
        fn = lambda do | row |
          Hash[col_names.zip(row)]
        end
      end
    end
    fn
  end
  
  def content_type ; nil ; end
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
