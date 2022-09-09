# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

module Boolean
  ::TrueClass.include self
  ::FalseClass.include self
  def self.boolean_or value, default = nil
    case value
    when true, false
      value
    else
      default
    end
  end
end

