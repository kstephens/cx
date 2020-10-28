# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Header
  include Enumerable, Logging
  extend Logging
  
  def inspect
    "#<#{self.class.name} #{"%0x" % object_id} #{name.inspect} #{@cols.inspect}>"
  end

  def initialize cols = nil, opts = nil
    self.cols = cols if cols
    @opts = opts || { }
  end
  attr_reader :cols, :name_to_col, :ind_to_col
  attr_accessor :name, :opts

  def << c
    self.cols = [ *cols, c ]
    self
  end

  def set_cols! cols
    _start_col_mapping!
    cols.each do | c |
      add_col! c
    end
    _finish_col_mapping!
    self
  end

  def add_col! c
    case c
    when Column
      col = c.dup_deep
    when String, Symbol
      col = Column.new(c)
    else
      raise TypeError, "Invalid column name : #{c.inspect} : #{@cols.inspect}"
    end
    _add_col! col
  end

  def _start_col_mapping!
    @cols        = [ ]
    @name_to_col = { }
    @ind_to_col  = { }
    @to_s = @to_h = @row_fn = nil
    self
  end

  def _add_col! col
    col.ind = @cols.size;
    if @name_to_col[col.name]
      col.name = :"#{col.name}__#{@cols.size}"
      log.warn "duplicate column #{col.to_s.inspect} #{col.ind} will be named #{col.name.to_s.inspect}"
    end
    col.header = self
    _col_! col
  end
  
  def _col_! col
    @cols[col.ind]         = col
    @name_to_col[col.name] = col
    @ind_to_col[col.ind]   = col
    @to_s = @to_h = @row_fn = nil
    col
  end
  
  def to_s
    @to_s ||= @cols.map(&:name).join(',').freeze
  end
  
  def to_h
    @to_h ||= Hash[@cols.map(&:name).zip(@cols.map(&:ind))]
  end

  def _finish_col_mapping!
    self
  end
  
  def dup_deep
    dup.dup_deepen!(self)
  end
  def dup_deepen! src
    @opts &&= @opts.dup # USED ???
    cols = @cols
    _start_col_mapping!
    cols.map(&:dup_deep).each{|col| _add_col! col}
    _finish_col_mapping!
  end
  alias :cols= :set_cols!
  
  def self.clean_col_name c
    c && c.to_s.gsub(/^%|%$/, '').gsub(/[\{\}\[\]\(\)]/, '').gsub(/[^-_\w]/, '_').to_sym
  end

  # Transform row.
  def row r, cols = nll
    row_fn(cols).call(r)
  end
  def col_row r, cols = nil
    (cols || self.cols).map{|c| [c, r[c.to_i]]}
  end
  def row_hash r, cols = nil
    Hash[col_row(r, cols)]
  end
  def row_as_hash r, cols = nil
    Hash[(cols || self.cols).map(&:to_sym).zip(row_fn(cols).call(r))]
  end
  def row_arry r, cols = nil
    row_fn(cols).call(r)
  end
  def row_fn cols = nil
    @row_fn ||= { }
    @row_fn[cols] ||=
      begin
        inds = self[cols || self.cols].map(&:to_i)
        lambda{|row| row.values_at(*inds)}
      end
  end
  
  def each &blk
    @cols.each(&blk)
    self
  end
  def size ; @cols.size ; end
  
  def [] x
    case x
    when Column  then x
    when Integer then @ind_to_col[x]
    when Symbol  then @name_to_col[x]
    when String  then @name_to_col[x.to_sym]
    when Enumerable then x.map{|x| self[x]}
    else
      nil
    end
  end
  def to_proc
    @to_proc ||= lambda{|x| self[x]}
  end
  alias :call :[]
  
  def col x
    case x
    when Column
      # May be from a different Header.
      col(x.to_sym)
    when Enumerable
      x.map{|x| col(x)}
    else
      self[x] or raise "Unknown column : #{x.inspect} in #{@ind_to_col.inspect}"
    end
  end

  def self.parse_column_args args, strip_and_split = true
    cols = args.dup
    if strip_and_split
      cols = cols.flat_map do |c|
        c.strip.split(/\s+|\s*,\s*/, -1).map(&:strip)
      end
    end
    cols.reject!(&:empty?)
    cols.map! do | c |
      if c =~ /^([^:]+)(:(.*))?$/
        name, opts = $1, $3 || ''
        case name
        when /^#?(\d+)$/
          i = $1.to_i
          raise "invalid numeric column specification #{c.inspect}}" unless i > 0
          name = i - 1
        end
        [ name, opts ]
      else
        raise_ "invalid column specifcation #{c.inspect}"
      end
    end
    cols.map! do | (name, opts) |
      kvs = opts.split(':').map do |kv|
        k, v = kv.split("=", 2)
        [ k.to_sym, v || true ]
      end
      [ name, Hash[kvs] ]
    end
    pp(cols: cols) if debug?
    cols
  end
    
  ###########################
  
  class Column
    include Logging
    attr_accessor :header, :name, :ind, :opts
    attr_reader :to_s
    alias :to_i   :ind
    alias :to_sym :name
    
    def initialize name, ind = nil
      self.name = name
      @ind = ind
      @opts = { }
    end
    
    def inspect
      "#<C #{@name.inspect} #{@ind.inspect} #{@opts.inspect}>"
    end

    def name= name
      @name = name.to_sym
      @to_s = name.to_s.freeze
      @header && @header._col_!(self)
    end

    def opts= opts
      opts.each do | k, v |
        sel = :"#{k}="
        if respond_to?(sel)
          send(sel, v)
        else
          @opts[k] = v
        end
      end
      self
    end
    def copy_to! other
      other.ind  ||= @ind
      other.opts = opts.merge(other.opts)
      other
    end
    def to_proc
      @to_proc ||= lambda{|x| x[@ind]}
    end
    def dup_deep
      dup.dup_deepen!(self)
    end
    def dup_deepen! src
      @opts    = @opts.dup
      @to_proc = nil
      self
    end
  end
end
end
