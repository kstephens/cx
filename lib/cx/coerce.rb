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
    input.map! do | r |
      header.map do |c|
        v = r[c.to_i]
        v = Typing.coerce(v, c.type) if c.type
        v
      end
    end
    app.call(input, env)
  end
end
end
