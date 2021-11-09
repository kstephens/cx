# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Args
    attr_accessor :argv, :args, :opts

    def parse! argv
      @argv = argv.map(&:dup)
      @args = @argv.map(&:dup)
      @opts = { }
      while arg = args.first
        case arg
        when /^--([-_a-z0-9]+)/i
          set_opt! $1, true
          args.shift
        when /^--([-_a-z0-9]+)=(.*)/i
          set_opt! $1, $2
          args.shift
        when '--'
          break
        else
          break
        end
      end
      {argv: argv, args: args, opts: opts}
    end

    alias :call :parse!

    def set_opt! key, val
      opts[key.gsub(/-/, '_').to_sym] = val
    end
  end
end

