# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  module EnumerableTable
  include Enumerable
  def header!
    @header or raise_ "does not have a header"
  end
  # Enumerable:
  def each(&blk)
    _rows.each(&blk)
    self
  end
  def empty? ; _rows.empty? ; end
  def first  ; _rows.first  ; end
  # Array-like:
  def [] i   ; _rows[i]     ; end # Used by transpose
  def size   ; _rows.size   ; end

  # Array-like Mutation:
  def clear        ; _rows_cow.clear               ; end
  def shift        ; _rows_cow.shift               ; end
  def unshift  x   ; _rows_cow.unshift x    ; self ; end
  def pop          ; _rows_cow.pop                 ; end
  def push     x   ; _rows_cow.push x       ; self ; end
  def map!     &b  ; _rows_cow.map! &b      ; self ; end
  def compact! &b  ; _rows_cow.compact! &b  ; self ; end
  def select!  &b  ; _rows_cow.select! &b   ; self ; end
  def compact!     ; _rows_cow.compact!     ; self ; end
  # def []= i, v  ## NOT NEEDED
  def concat enum
    enum = enum._rows if EnumerableTable === enum
    _rows_cow.concat(enum)
    self
  end
  # I/O like:
  def write row ; _rows_cow << row ; self ; end
  alias :<< :write

  def inspect mode = nil
    id = @identifier || "#{'%x' % object_id}"
    str = "#<#{self.class.name} #{id} #{size} #{(@header && @header.cols).inspect}>"
    case mode
    when :rows
      str = String.new << str << "\n"
      str << "#{size} vvvvvvvvvvvvvvvvvvvv\n"
      each{|e| str << e.inspect << "\n"}
      str << "#{size} ^^^^^^^^^^^^^^^^^^^^\n"
    end
    str
  end
end

class Table2
  include EnumerableTable, Logging
  attr_accessor :identifier, :header, :input, :rows
  def initialize header = nil, rows = nil
    @header = header
    @rows   = rows
  end
  def _rows     ; @rows ||   (@input && @input.rows) || @input  ; end
  def _rows_cow ; @rows ||= ((@input && @input.rows) || []).dup ; end
  def header
    @header || (@input && @input.header)
  end
  # Functional: returns new Table
  def map(&blk)
    Table2.new(header, _rows.map(&:blk))
  end
end

class Table
  include EnumerableTable, Logging
  attr_accessor :identifier, :header, :rows

  def initialize header = nil, rows = nil
    @header = header
    @rows = rows || [ ]
  end
=begin
  def identifier= x
    @identifier = x
    ObjectSpace.define_finalizer(self, self.class.finalize_proc("#{'%x' % object_id} creator: #{@identifier}"))
  end
  def self.finalize_proc id
    proc { puts "  ### finalized #{self} #{id}" }
  end
=end
  
  def new header = nil, rows = nil
    x = self.class.new(header, rows)
    x.header ||= @header
    x
  end
  
  def _rows     ; @rows ; end
  def _rows_cow ; @rows ; end
  # Optimization:
  def clear     ; @rows = [ ] ; end

  def dup_deep
    dup.dup_deepen! self
  end
  def dup_deepen! src
    @rows     = @rows.map{|r| r.dup}
    @header &&= @header.dup_deep
    @opts     = @opts.dup
    self
  end
end
end
