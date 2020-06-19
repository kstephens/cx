# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/structured'
require 'json'

module CX
class JsonIn < Pipe
  include Pipe::Parse
  def init_more!
    require 'json'
    super
  end
  def call input, env
    stream = input.rows * '' # EXPENSIVE: See deleted RowReader for a broken alternative
    pp(stream: stream) if debug?
    rows = JSON.load(stream)
    raise unless Array === rows
    pp(json: rows)  if debug?
    
    header, keys = header_from_hash_keys(input.header, rows)
    output = new_table(input)
    output.header = header
    pp(in_header: input.header, header: header, key_to_col: key_to_col) if debug?
    rows.each_shift do | row |
      pp(row: row) if debug?
      row = row.values_at(*keys) if Hash === row
      pp(row_: row) if debug?
      output << row
    end
    app.call(output, env)
  end

  def header_from_hash_keys header, rows
    keys = nil
    if Hash === rows.first
      keys = Set.new # Assumes Sets are ordered.
      rows.each do | row |
        keys.merge(row.keys) if Hash === row
      end
      header = keys.empty? ? header : Header.new(keys.to_a)
    end
    [ header, keys ]
  end
end

class JsonOut < StructuredOut
  def init_more!
    require 'json'
    super
  end
  def line row, row_delim
    # TODO: handle alternate row_delim
    JSON.dump(row)
  end
  def row_sep
    super || ','
  end
end

end
