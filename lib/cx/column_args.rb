# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/inspect'
require 'cx/logging'

module CX
  class ColumnArg < Struct.new(:name, :index, :opts, :args, :arg_str, :rest_str, :column, :wildcard)
    def header_column! c
      self.column = c
      self.name = c.name
      self.index = c.order
      self.opts = { }
      self.args = [ ]
      self.arg_str = ""
      self.rest_str = ""
      self
    end
  end
    
  class ColumnArgs
    include Enumerable, Support

    attr_reader :args, :header

    def initialize
      @args = [ ]
      @header = nil
    end

    def inspect_content modes
      args.map(&:inspect) * ', '
    end
    
    def each &blk
      @args.each(&blk)
    end
    def size  ; @args.size  ; end
    def first ; @args[0]    ; end
    def last  ; @args[-1]   ; end
    def [] i  ; @args[i]    ; end
    
    def parse! _args
      _args.each do | arg_str |
        @args << parse_arg(arg_str)
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
      if /^(\d+)+$/.match?(name) && (i = name.to_i) > 0
        index = i - 1
      end
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
      end
      c
    end
    
    def bind! header
      @header = header
      @args.each do | ca |
        if ca.column ||=
            (ca.index && header.ordered[ca.index]) ||
            header.get(ca.name) ||
            header.find{|c| c.name_ == ca.name}
          ca.index = ca.column.order
        end
      end
      self
    end

    def wildcards!
      new_cas = [ ]
      scan = @args.dup
      while ca = scan.shift
        case
        when ca.name == :*
          @header.ordered.each do |c|
            unless new_cas.find{|ca| ca.column == c}
              ca = ColumnArg.new.header_column!(c)
              ca.args = ca.args.map(&:dup)
              ca.opts = ca.opts.dup
              ca.arg_str = ca.arg_str.dup
              ca.rest_str = ca.rest_str.dup
              ca.wildcard = true
              new_cas << ca
            end
          end
        else
          new_cas.reject! do |x|
            x.column == ca.column and x.wildcard
          end
          new_cas << ca
        end
      end
      @args = new_cas
      self
    end

    def or_all!
      if @args.empty?
        @args = @header.ordered.map{|c| ColumnArg.new.header_column!(c)}
      end
      self
    end
    
    def unbound
      @args.reject(&:column)
    end
    
    def bound
      @args.select(&:column)
    end

    def check!
      unless (ub = unbound).empty?
        msg = ub.map(&:arg_str).map(&:inspect).join(', ')
        raise_ CX::Error, "unknown column: #{msg}"
      end
      self
    end
    
    def columns
      bound.map(&:column)
    end
  end
end

