# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

$:.unshift "lib"

require 'cx'
require 'cx/header'
require 'cx/column'
require 'cx/row'
require 'cx/inspect'
require 'cx/logging'

module CX
  class Table
    include Enumerable
    attr_reader :rows, :header, :meta

    def inspect mode = nil
      case mode
      when :super
        super()
      when :detail
        map(&:to_h).inspect
      else
        "#<#{self.class} #{size} #{header.inspect(mode)}>"
      end
    end

    def initialize rows = nil, header = nil, meta = nil
      @meta ||= meta || Meta.new
      @rows ||= rows || [ ]
      @header = nil
      self.header = header
    end

    def new ; dup.deepen! ; end
    def new_empty
      self.class.new(nil, @header.dup, @meta.dup)
    end

    def deepen!
      @meta = @meta.dup.deepen!
      @rows = @rows.map(&:dup)
      self
    end

    def header= h
      return if @header == h
      @header = h
      @rows.each do | r |
        r._header = h 
      end
      self
    end
    alias :header! :header=

    def [] i
      @rows[i]
    end

    def size; @rows.size; end

    def each &blk
      @rows.each(&blk)
      self
    end

    def push r
      @rows.push make_row(r)
      self
    end
    alias :<< :push

    def unshift r
      @rows.unshift make_row(r)
      self
    end

    def make_row r
      r = Row[r]
      r._header = @header
      # puts r.inspect(:super)
      r
    end

    def pop   ; @rows.pop   ; end
    def shift ; @rows.shift ; end
    def concat rows
      rows = rows.map{|r| make_row(r)}
      @rows.concat(rows)
      self
    end

    def select! &blk
      @rows.select!(&blk)
      self
    end

    def each_row_col
      @rows.each do | r |
        @header.each do | c |
          yield r, c
        end
      end
      self
    end

    def each_row_col_val
      @rows.each do | r |
        @header.each do | c |
          yield r, c, r[c]
        end
      end
      self
    end

    def write out = nil
      out ||= $stdout
      each{|r| r.write(out)}
      nil
    end
  end
end
