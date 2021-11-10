# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class IOOut
      include Xform
      
      # :COMMAND:
      # IOOut:
      #   name: out
      #   aliases: o
      #   synopsis: Emit lines to a file
      #   args: [ filename, ... ]
      #   opts: {}
      def initialize!
        super
        binding.pry unless args
        @io = args[0] || $stdout
      end

      def call input, env
        open(@io, "w") do | io |
          input.each do | r |
            r.each do | _c, v |
              io.write(v)
            end
          end
        end
        input
      end

      def open io, mode
        case io
        when IO
          yield io
        when String
          File.open(io.to_s, mode) do | io |
            yield io
          end
        else
         raise TypeError
        end
      end
    end
  end
end

