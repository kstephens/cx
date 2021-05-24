# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/csv'

module CX
  class TsvIn < CsvIn
    def init_more!
      opts[:separator] ||= "\t"
      super
    end
  end

  class TsvOut < CsvOut
    def init_more!
      opts[:separator] ||= "\t"
      super
    end
  end
end
