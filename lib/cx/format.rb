# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Format < Struct.new(:mod, :parser, :formatter, :coerce, :name)
    def initialize *args
      super
      self.name ||= mod.name.to_sym
      self.formatter ||= DEFAULT_FORMATTER
    end

    def parse v, fmt = nil
      case v
      when mod, nil
        v
      else
        parser.call(v, fmt)
      end
    rescue
      nil
    end

    def format v, fmt = nil
      formatter.call(v, fmt)
    end

    DEFAULT_FORMATTER = Proc.new do | v, fmt |
      fmt ? (fmt % v) : v.to_s
    end
  end
end
