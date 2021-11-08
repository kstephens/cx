# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Coerce < Pipe
  include Pipe::Process, Pipe::NeedsHeader
  def call input, env
    header = input.header!
    header.each do |c|
      c.clear_min_max!
    end
    input.map! do | r |
      header.map do |c|
        begin
          v = r[c.to_i]
          if c.type
            v = Typing.coerce(v, c.type)
          end
          c.col_min_max!(v) unless v.nil?
          v
        rescue => e
          raise "in column #{c} : row #{r} : #{e.inspect}"
        end
      end
    end
    app.call(input, env)
  end
  
end
end
