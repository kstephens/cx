# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/inspect'
require 'cx/logging'

module CX
  class Column
    include Inspect, Logging
    attr_reader :name, :index, :order, :meta, :header
    attr_reader :to_s, :name_ # Derived
    alias :to_sym :name
    alias :to_i   :index

    def initialize name = nil, order = nil, index = nil
      @meta = Meta.new
      self._name = name
      self._order = order
      self._index = index
    end

    ##################################

    def _header= h
      @header = h
      self
    end

    def name= n
      return if @name == n
      self._name = (@name && @header && @header.change_name!(self, n)) || n
    end

    def _name= n
      @name = n
      @to_s = @name.to_s.freeze
      @name_ = Column.simple_name(@name).to_sym
    end

    ##################################

    def self.simple_name name
      name.to_s.
        gsub(/^%|%$/, '').
        gsub(/[\{\}\[\]\(\)]/, '').
        gsub(/[^-_\w]/, '_').
        downcase
    end

    ##################################

    def index= i
      return if @index == i
      self._index = (@index && @header && @header.change_index!(self, i)) || i
    end

    def _index= i
      @index = i
    end

    ##################################

    def order= i
      case i
      when nil
        @order = nil
      when @order
        # NOTHING
      else
        self._order = (@order && @header && @header.change_order!(self, i)) || i
      end
    end

    def _order= i
      @order = i
    end

    ##################################

    def dup
      super.deepen!
    end
    
    def deepen!
      @header = nil
      @meta = @meta.dup
      self
    end

    def inspect_content mode
      name.inspect
    end

  end
end

