# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Row
    include Enumerable

    attr_reader :header, :data, :header_version
    attr_accessor :file_name, :line_number

    def inspect_content mode
      to_h.inspect
    end

    def self.[] x
      case x
      when self, nil
        x
      else
        new(x)
      end
    end

    def initialize data = nil, header = nil
      @data = data
      @header = header
    end

    def new ; dup.deepen! ; end
    def deepen!
      @data = @data.dup
      @meta = @meta && @meta.dup
      self
    end

    def _header= h
      @header = h
      self
    end

    def each &blk
      @header.each do |c|
        yield c, _get(c)
      end
    end

    def size
      @header.size
    end

    ###########################

    def _get k
      return nil unless k
      case @data
      when Hash
        @data[k.to_sym]
      else
        @data[k.to_i]
      end
    end

    def _set k, v
      raise TypeError unless k
      case @data
      when Hash
        @data[k.to_sym] = v
      else
        @data[k.to_i] = v
      end
    end

    def [] k
      case k
      when Column
        _get(k)
      when Symbol, String, Integer
        _get(@header[k])
      when nil
        nil
      else
        raise TypeError, "[] : unexpected #{k.inspect}"
      end
    end

    def vals x
      x.map{|k| _get(k)}
    end

    def []= k, v
      case k
      when Column
        _set(k, v)
      when Symbol, String, Integer
        _set(@header[k], v)
      when nil
        nil
      else
        raise TypeError, "[]= : unexpected #{k.inspect}"
      end
    end

    def keys
      @header
    end

    def values
      @header.map{|c| _get(c)}
    end
    alias :to_a :values

    def first ; _get(@header.first) ; end
    def last  ; _get(@header.last)  ; end

    def to_h
      h = { }
      @header.each{|c| h[c.to_sym] = _get(c)}
      h
    end

    def write out = nil
      out ||= $stdout
      each{|v| out.write(v.to_s)}
      nil
    end
  end
end

