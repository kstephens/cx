# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class NormalizeColumns < Pipe
    include Pipe::NeedsHeader
    def call input, env
      input.header.each do | col |
        log.debug "Renaming #{col.name.inspect} to #{col.clean_name}" unless col.name == col.clean_name 
        col.name = col.clean_name
      end
      app.call(input, env)
    end
  end
end

