# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# Region:
#   aliases: range
#   synopsis: Select a range of rows.
#   args: []
#   opts:

module CX
  module Xform
    class Region
      include Xform
      def call input, env
        regions = args.flat_map do|arg|
          arg.strip.split(/\s+|\s*,\s*/)
        end.map{|arg| parse_region(input, arg)}

        output = input.dup_empty
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
        a = b = arg
        exc = false
      when /^([^.]+)\.\.(\.)?([^.]+)$/
        a, exc, b = parse_region(input, $1), $2,  parse_region(input, $3)
        a = a.first
        b = b.first
      else
        raise_ "Invalid range #{arg.inspect}"
      end
      a = input.size + a if a < 0
      b = input.size + b if b < 0
      a = [[a, 0].max, input.size - 1].min
      b = [[b, 0].max, input.size - 1].min
      [ a, b, ! ! exc ]
    end
  end
end

