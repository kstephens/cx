# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

# :COMMAND:
# IoIn:
#   aliases: in,i
#   synopsis: Read from a file.
#   args: [ filename, ... ]
#   opts: {}

# IoOut:
#   aliases: out,o
#   synopsis: Write records to a file.
#   args: [ filename, ... ]
#   opts: {}

module CX
  module Xform
    module IoBase
      include Xform
      
      def initialize!
        super
        raise_ ArgumentError, "too many arguments" if args.size > 1
        @io = args[0]
      end
      
      def open io, mode, env
        case io
        when '-', nil
          open default_io, mode, env
        when IO, StringIO
          begin
            yield io
          ensure
            io.flush rescue nil
          end
        when String
          file_name = io.to_s.dup.freeze
          File.open(file_name, mode) do | ioh |
            env[:io_file] = file_name
            yield fh
          end
        else
          raise_ TypeError, "cannot open #{io.inspect} #{mode.inspect}"
        end
      end
    end

    class IoIn
      include IoBase
      def call input, env
        open(@io, "r", env) do | ioh |
          Table.new([ioh.read], Header.new([:_DATA_]).each{|c| c.meta.type == :String})
        end
      end
      def default_io ; $stdin ; end
    end
    
    class IoOut
      include IoBase
      def call input, env
        open(@io, "w", env) do | ioh |
          # io.write("=== BEGIN ===========================\n")
          input.each do | r |
            r.each do | _c, v |
              ioh.write(v)
            end
          end
          # io.write("=== END   ===========================\n\n")
        end
        input
      end
      def default_io ; $stdout ; end
    end
  end
end

