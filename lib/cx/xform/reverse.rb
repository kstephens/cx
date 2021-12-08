# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

# :COMMAND:
# Reverse:
#   aliases: [ tac ]
#   synopsis: Reverse order of rows.
#   args: []
#   opts:
#   examples:
#     - cx in SOME.csv // -h // reverse // h-
#     - cx in SOME.csv // reverse


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

