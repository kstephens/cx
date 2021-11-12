# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/boolean'

module CX
  class Meta
    ATTRS =
      [
        [:name,       type: String],
        [:name_,      type: String],
        [:visible,    type: Boolean],
        [:order,      type: Integer],
        [:index,      type: Integer],
        [:type,       type: String],
        [:min_size,   type: Integer],
        [:max_size,   type: Integer],
        [:min_value,  type: Object],
        [:max_value,  type: Object],
        [:blanks,     type: Integer],
        [:nulls,      type: Integer],
        [:format,     type: String],
        [:align,      type: Symbol],
        [:align_inferred, type: Symbol],
        [:types,      type: String],
        [:type_inferred, type: String],
      ]
    attr_accessor *ATTRS.map(&:first)

    def initialize
      self.visible = true
      clear!
    end

    def deepen!
      @types = @types.dup
      self
    end

    def inspect
      "#<#{self.class} #{to_h.inspect}>"
    end

    def clear!
      @types = Set.new
      @type_inferred = @align_inferred = nil
      @min_width = @max_width = @min_value = @max_value = nil
      @blanks = @nulls = 0
      self
    end

    def min_max_size! n
      @min_size = n if ! @min_size || @min_size > n
      @max_size = n if ! @max_size || @max_size < n 
      self
    end

    def min_max_value! val
      @min_value = val if ! @min_value || @min_value > val
      @max_value = val if ! @max_value || @max_value < val
      self
    rescue
      nil
    end

    def type! type
      @types << type
      self
    end

    def update m
      m.to_h.each do | k, v |
        send(:"#{k}=", (v.dup rescue v))
      end
      self
    end

    def align_ ; align || align_inferred; end

    def to_h
      ATTRS.map(&:first).map{|k| [k, send(k)]}.to_h
    end

    def table
      header = Header.new
      ATTRS.each do | (name, opts) |
        opts[:align_inferred] ||= align_for_type(opts[:type_inferred] || opts[:type])
        opts[:align] ||= align_for_type(opts[:type])
        col = Column.new(name).tap{|c| c.meta.update(opts)}
        col.meta.type = opts[:type]
        header << col
      end
      header[:min_value].meta.type =
        header[:max_value].meta.type =
       self.type
     Table.new([], header)
    end
    
    def align_for_type type
      type && type <= ::Numeric ? :right : nil
    end

    def type_
      self.type  || self.type_inferred
    end
    def align_
      self.align || self.align_inferred || align_for_type(type_)
    end
  end
end

