# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class MetaTable
      include Xform
      def call input, env
        output = input.header.meta.table
        # output << input.header.meta.to_h
        input.header.each do | c |
          output << c.meta.to_h
        end
        CalculateMeta.new.call(output, env)
      end
    end
  end
end

