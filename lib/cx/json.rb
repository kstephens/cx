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
    JSON.load(input)
  end
end

class JsonOut < StructuredOut
  def content_type ; 'application/json' ; end
  def init_more!
    super
    opts[:seq_delim] ||= '[]'
    if row_mode?
      opts[:row_delim] ||= '[]'
    else
      opts[:row_delim] ||= '{}'
    end
  end

  def line row
    # TODO: handle alternate row_delim
    JSON.dump(row)
  end
  
  def row_sep ; super || ',' ; end
end

end
