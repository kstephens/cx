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

    def match? x
      case x
      when nil
      when Symbol
        name == x
      when String
        name == x.to_sym
      when Column
        column == x
      when Integer
        case
        when x >= 0
          index == x
        when x < 0
          column && index == column.header.size + x
        end
      when ColumnArg
        self.object_id == x.object_id
      else
        raise_ ArgumentError, "match? : invalid #{x.inspect}"
      end
    end

    def to_s      ; name.to_s ; end
    alias :to_sym  :name
    alias :to_i    :index
  end
    
  class ColumnArgs
    include Enumerable, Support, Rx

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
    def find x, bound_only = nil
      cas = bound_only || @header ? bound : @args
      cas.find do | ca |
        ca.match? x
      end if x
    end
    def include? x, bound_only = nil
      ! ! find(x, bound_only)
    end
    
    def parse_split_arg! arg, sep = ','
      parse! arg.split(sep) if arg
      self
    end

    def parse! _args
      _args.each do | arg_str |
        @args << parse_arg!(arg_str)
      end
      self
    end

    def parse_arg! arg_str
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
      if /^(-?\d+)$/.match?(name) and i = name.to_i and ! i.zero?
        index = i
      end
      c = ColumnArg.new(
        index ? nil : name.to_sym,
        index,
        opts,
        args,
        arg_str,
        rest_str,
      )
      if name =~ /[*?]/
        c.index = nil
        c.wildcard = true
      end
      c
    end
    
    def bind! header
      raise_ ArgumentError, "bind! : already bound" if @header
      @header = header
      @args.each do | ca |
        col = nil
        ca.column ||=
          case
          when ca.index && ca.index > 0
            header.ordered[ca.index - 1]
          when ca.index && ca.index < 0
            header.ordered[header.ordered.size + ca.index]
          when ca.index
            log.error "invalid column index : #{ca.arg_str.inspect}"
            nil
          when col = header.get(ca.name)
            col
          when col = header.find{|c| c.name_ == ca.name}
            col
          end
        ca.column and ca.index = ca.column.order
      end
      self
    end

    def wildcards!
      raise_ ArgumentError, "wildcards! : not bound" unless @header
      new_cas = [ ]
      scan = @args.dup
      while ca = scan.shift
        if ca.wildcard
          rx = wildcard_rx(ca.name.to_s) 
          @header.ordered.select{|c| rx.match(c.to_s) }.each do |c|
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

    def wildcard_rx name
      Regexp.new('^' + glob_to_rx(name.to_s) + '$')
    end
  end
end

