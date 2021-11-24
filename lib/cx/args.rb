# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Args
    attr_accessor :argv, :args, :opts

    def initialize
      @argv = [ ]
      @args = [ ]
      @opts = { }
    end
    
    def parse! argv, o = { }
      argv = argv.dup
      @argv.concat(argv)
      x = argv.dup
      while arg = x.shift
        case arg
        when String
          case arg
          when /^--no-([-_a-z0-9]+)$/i
            set_opt! $1, false
          when /^--([-_a-z0-9]+)$/i
            set_opt! $1, true
          when /^--([-_a-z0-9]+)=(.*)$/i
            set_opt! $1, $2
          when '--'
            @args.concat(x)
            break
          else
            @args << arg
            if o[:no_args]
              @args.concat(x)
              break
            end
          end
        else
          @args << arg
          if o[:no_args]
            @args.concat(x)
            break
          end
        end
      end
      self
    end

    alias :call :parse!

    def set_opt! key, val
      @opts[key.gsub(/-/, '_').to_sym] = val
    end

    def to_h
      {
        argv: @argv,
        args: @args,
        opts: @opts,
      }
    end

    alias :to_a :argv
  end
end

