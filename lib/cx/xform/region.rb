# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class Region
      include Xform
      # :COMMAND:
      # Region:
      #   name: region
      #   aliases: range
      #   synopsis: Select a range of rows.
      #   args: []
      #   opts:
      def call input, env
        regions = args.flat_map do|arg|
          arg.strip.split(/\s+|\s*,\s*/)
        end.map{|arg| parse_region(input, arg)}

        output = input.new_empty
        regions.each do | (a, b, exc) |
          rows = a <= b ?
            input[Range.new(a, b, exc)] :
            input[Range.new(b, a, exc)].reverse!  
          output.concat(rows)
        end
        output
      end
    end

    def parse_region input, arg
      case arg
      when /^([-+]?\d+)$/
        arg = arg.to_i - 1
        arg = input.size + arg + 1 if arg < 0
        [ arg, arg, false ]
      when /^([^.]+)\.\.(\.)?([^.]+)$/
        a, exc, b = parse_region(input, $1), $2, parse_region(input, $3)
        a = a.first; b = b.first
        [ a, b, ! ! exc ]
      else
        raise_ "Invalid range #{arg.inspect}"
      end
    end
  end
end

