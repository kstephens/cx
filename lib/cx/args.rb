# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Args
    attr_accessor :argv, :args, :opts

    def self.[] argv
      # binding.pry
      new.parse!(argv)
    end
    
    def parse! argv
      @argv = argv.map(&:dup)
      @args = [ ]
      @opts = { }
      x = argv.dup
      while arg = x.shift
        # pp(arg: arg, x: x)
        case arg
        when /^--([-_a-z0-9]+)$/i
          set_opt! $1, true
        when /^--([-_a-z0-9]+)=(.*)$/i
          set_opt! $1, $2
        when '--'
          self.args += x
          break
        else
          self.args << arg
        end
        
      end
      self
    end

    alias :call :parse!

    def set_opt! key, val
      opts[key.gsub(/-/, '_').to_sym] = val
    end
  end
end

