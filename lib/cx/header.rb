# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/column'
require 'cx/logging'
require 'cx/inspect'

module CX
  class Header
    include Enumerable, Inspect, Logging
    # extend Logging

    attr_reader :columns, :meta, :aliases, :version

    def initialize cols = nil
      @version = 0
      @columns = [ ]
      @to_column = { }
      @aliases = { }
      @meta = Meta.new
      case cols
      when nil
      when Integer
        cols.times do | i |
          push Column.new(:"_COL_#{i}")
        end
      when Enumerable
        cols.each{|x| push x}
      else
        raise_ TypeError, "unexpected columns : #{columns.class}"
      end
      compact!
      @version = 0
    end

    def [] k
      case k
      when Integer
        @columns[k]
      when Symbol, String
        @to_column[k.to_sym] || @to_column[@aliases[k.to_sym]]
      else
        raise TypeError, "Header[] : unexpected #{k.class}"
      end
    end

    def get k
      case k
      when nil
        nil
      when Integer
        @columns[k]
      when Symbol, String
        @to_column[k.to_sym] || @to_column[@aliases[k.to_sym]]
      else
        nil
      end
    end
    
    def size  ; @columns.size  ; end
    def first ; @columns.first ; end
    def last  ; @columns[-1]   ; end

    def new ; dup.deepen! ; end
    def deepen!
      @to_column = { }
      @aliases = @aliases.dup
      @columns = @columns.map do |c|
        @to_column[c.to_sym] = c = c.dup
        c._header = self
        c
      end
      @meta = @meta.dup
      @version = 0
      self
    end

    def each &blk
      @columns.each(&blk)
      self
    end

    def push x
      case x
      when Column
        add_column!(x)
      when Symbol, String
        push Column.new(x)
      else
        raise TypeError
      end
      self
    end
    alias :<< :push

    def concat x
      case x
      when Header
        concat x.columns
      when Enumerable
        x.map{|c| add_column!(c)}
      else
        raise TypeError
      end
      compact!
    end
    

    def alias! c, name
      @aliases[name] = c.name
      self
    end

    def add_column! c
      raise ArgumentError if @columns.include?(c)
      c.index ||= (@columns.map(&:to_i).max || -1) + 1
      c.order ||= @columns.last ? @columns.last.order + 1 : 0
      c.name = available_name(c, c.name || :_COL_)
      @to_column[c.name] = c
      make_room_at! c.order
      @columns << c
      compact!
      @version += 1
      c._header = self
      c
    end

    def remove_column! c
      raise ArgumentError unless @columns.include?(c)
      @to_column.delete(c.name)
      @columns.delete(c)
      c._header = nil
      compact!
      @version += 1
      c
    end

    def compact!
      @columns = @columns.compact.sort_by(&:index)
      self
    end

    def available_name c, name
      return name unless @to_column[name]
      new_name = name
      i = (c ? c.to_i : @columns.map(&:to_i).max) + 1
      while @to_column[new_name = :"#{name}#{i}"]
        i += 1
      end
      new_name
    end

    def change_name! c, name
      return name if c.name == name
      raise ArgumentError if @to_column[name]
      raise ArgumentError unless @columns.include?(c)
      @to_column.delete(c.name)
      @aliases.keys do | (a, n) |
        @aliases.delete(a) if n == c.name
      end
      new_name = available_name(c, name)
      c._name = new_name
      @to_column[new_name] = c
      alias! c, c.name_
      @version += 1
      new_name
    end

    def change_index! c, index
      return index if c.index == index
      raise ArgumentError unless @columns.include?(c)
      make_room_at! index
      c._index = index
      compact!
      @version += 1
      index
    end

    def change_order! c, order
      return index if c.order == order
      raise ArgumentError unless @columns.include?(c)
      make_room_at! order
      c._order = order
      compact!
      @version += 1
      order
    end

    def make_room_at! order
      @columns.select{|c| c.order >= order}.each do |c|
        c.order += 1
      end
      self
    end

    def to_row x
      case x
      when Row
        x
      when Hash, Array
        Row.new(x, self)
      else
        raise TypeError
      end
    end

    def size   ; @columns.size ; end
    def keys   ; @to_column.keys ; end
    def values ; @to_column.values ; end

    def ordered
      @columns.sort_by{|c| c.order || -1}
    end
    
    def inspect_content mode
      "#{map(&:to_sym)}"
    end
  end
end
