# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  module Inspect
    def inspect *modes
      case
      when modes.include?(:super)
        super()
      else
        content = inspect_content(modes)
        content = content ? " #{content.to_s}" : ""
        content = "#{object_id}#{content}" unless modes.include?(:no_id)
        "#<#{self.class} #{object_id}#{content}>"
      end
    end

    def inspect_content modes
      nil
    end
  end
end

