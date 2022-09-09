# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/meta'
require 'cx/inspect'
require 'cx/logging'

module CX
  class Column
    include Support, Meta::Owner
    attr_reader :name, :index, :order, :header, :version
    attr_reader :to_s, :name_ # Derived
    alias :to_sym :name
    alias :to_i   :index

    def initialize name = nil, order = nil, index = nil
      @version = 0
      self.meta = Meta.new(self)
      self._name = name
      self._order = order
      self._index = index
      # @version is > 0; reset it.
      @version = -1
      inc_version!
    end

    def inc_version!
      # @meta.version =
      (@version += 1)
      self
    end

    def clear!
      @header = @order = @index = nil
      # ??? @version = 0
      # ??? @meta.column!(self)
      self
    end

    ##################################

    def _header= h
      @header = h
      # inc_version! ???
      self
    end

    def name= n
      n = n.to_sym
      return if @name == n
      self._name = (@name && @header && @header.change_name!(self, n)) || n
    end

    def _name= n
      @name = n.to_sym
      @to_s = @name.to_s.freeze
      @name_ = Column.simple_name(@to_s).to_sym
      @meta.column!(self)
      inc_version!
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
      # ??? @meta.column!(self)
      inc_version!
    end

    ##################################

    def order= i
      case i
      when nil
        # ??? self._order = nil
        @order = nil
      when @order
        # NOTHING
      else
        self._order = (@order && @header && @header.change_order!(self, i)) || i
      end
    end

    def _order= i
      @order = i
      @meta.column!(self)
      inc_version!
    end

    ##################################

    def meta_clear!
      @meta.clear!(self)
      inc_version!
      @meta
    end
    
    ##################################

    def initialize_copy orig
      super
      @header = nil
      self.meta = @meta.dup
    end

    def inspect_content mode
      name.inspect
    end
  end
end

