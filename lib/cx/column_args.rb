# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/inspect'
require 'cx/logging'

module CX
  class ColumnArg < Struct.new(:name, :index, :opts, :args, :arg_str, :rest_str, :column)
  end
    
  class ColumnArgs
    include Enumerable, Inspect, Logging

    attr_reader :columns

    def initialize
      @columns = [ ]
    end

    def each &blk
      @columns.each(&blk)
    end

    def parse! _args
      _args.each do | arg_str |
        @columns << parse_arg(arg_str)
      end
      self
    end

    def parse_arg arg_str
      name = index = rest_str = nil
      opts = { }
      args = [ ]
      case arg_str
      when /^([^:]+):(.*)$/
        name, rest_str = $1, $2
        rest_str.split(/;/).each do | elem |
          case elem
          when "-"
            opts[:order] = -1
          when "+"
            opts[:order] = 1
          when "!"
            opts[:negate] = true
          when /^([^=]+)=(.*)$/
            opts[$1.to_sym] = $2
          else
            args << elem
          end
        end
      else
        name = arg_str
        rest_str = ""
      end
      index = (name =~ /^\d+$/ and name.to_i)
      index &&= index - 1
      c = ColumnArg.new(
        index ? nil : name.to_sym,
        index,
        opts,
        args,
        arg_str,
        rest_str,
      )
      if c.name == :*
        c.index  = nil
        c.column = :REST
      end
      c
    end
    
    def bind! header
      @columns.each do | c |
        c.column ||= header[c.name] || header[c.index]
      end
      self
    end

    def collapse!
      @all = @columns.dup
      @selected = @columns
      self
    end
    
  end
end

