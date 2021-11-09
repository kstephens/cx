# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  module Inspect
    def inspect mode = nil
      case mode
      when :super
        super()
      else
        "#<#{self.class} #{object_id}#{inspect_content}>"
      end
    end

    def inspect_content
      ''
    end
  end
end

