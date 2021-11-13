# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

# :COMMAND:
# Reverse:
#   aliases:
#   synopsis: Reverse order of rows.
#   args: []
#   opts:

module CX
  module Xform
    class Reverse
      include Xform
      def call input, env
        input.rows.reverse!
        input
      end
    end
  end
end

