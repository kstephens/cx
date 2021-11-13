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
        content = inspect_content(mode)
        content = content ? " #{content.to_s}" : ""
        "#<#{self.class} #{object_id}#{content}>"
      end
    end

    def inspect_content mode
      nil
    end
  end
end

