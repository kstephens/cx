# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

# :COMMAND:
# IOOut:
#   name: out
#   aliases: o
#   synopsis: Emit lines to a file
#   args: [ filename, ... ]
#   opts: {}

module CX
  module Xform
    class IOOut
      include Xform
      
      def initialize!
        super
        @io = args[0] || $stdout
      end

      def call input, env
        open(@io, "w", env) do | io |
          # io.write("=== BEGIN ===========================\n")
          input.each do | r |
            r.each do | _c, v |
              io.write(v)
            end
          end
          # io.write("=== END   ===========================\n\n")
        end
        input
      end

      def open io, mode, env
        case io
        when IO, StringIO
          yield io
        when String
          File.open(io.to_s, mode) do | o |
            env[:in_file] = io.to_s
            yield o
          end
        else
          raise TypeError, "not writable : #{io.inspect}"
        end
      end
    end
  end
end

