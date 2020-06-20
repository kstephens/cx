# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/structured'
require 'json'

module CX
class JsonIn < StructuredIn
  include Pipe::Parse
  def parse input, env
    # EXPENSIVE: See deleted RowReader for a broken alternative
    JSON.load(input.rows * '' )
  end
end

class JsonOut < StructuredOut
  def content_type ; 'application/json' ; end
  def line row, row_delim
    # TODO: handle alternate row_delim
    JSON.dump(row)
  end
  def row_sep
    super || ','
  end
end

end
