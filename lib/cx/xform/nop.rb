# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class Nop
      include Xform
      # :COMMAND:
      # Nop:
      #   name: nop
      #   aliases: noop
      #   synopsis: Does nothing output is same as input.
      #   args: []
      #   opts: {}

      def call input, env
        input
      end
    end
  end
end

