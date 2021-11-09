# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

$:.unshift "lib"

require 'cx'
require 'cx/type'
require 'cx/args'
require 'cx/meta'
require 'cx/inspect'
require 'cx/xform/metatable'
require 'cx/xform/pipeline'
require 'cx/xform/strip'
require 'cx/xform/empty_to_null'
require 'cx/xform/calculate_meta'
require 'cx/xform/quote'
require 'cx/xform/line_out'
require 'cx/xform/io'
require 'cx/xform/align'
require 'cx/xform/csv'
require 'cx/xform/markdown'

require 'awesome_print'
require 'pry'

# What is needed?
# Tables
#   Columns
#   Metadata
# Records
#   Columns
#   Metadata
# Columns
#   Names
#   Position
#   Metadata

module CX
  class Column
    include Inspect
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
    return if @order == i
    self._order = (@order && @header && @header.change_order!(self, i)) || i
  end

  def _order= i
    @order = i
  end

  ##################################

  def deepen!
    @meta = @meta.dup
    self
  end
end

class Header
  include Enumerable
  attr_reader :columns, :meta, :aliases

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
      cols.each{|x| push x} if cols
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
      raise TypError
    end
  end

  def first ; @columns.first ; end
  def last  ; @columns.last  ; end
  
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
    self
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
    @columns = @columns.compact.sort_by(&:order)
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

  def inspect mode = nil
    case mode
    when :super
      super()
    else
      "#<#{self.class} #{object_id} #{map(&:to_sym)}>"
    end
  end
end

class Table
  include Enumerable
  attr_reader :rows, :header

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

  def initialize rows = nil, header = nil
    @meta ||= Meta.new
    @rows ||= [ ]
    @header = nil
    self.header = header
  end

  def new ; dup.deepen! ; end
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
  
  def each &blk
    @rows.each(&blk)
    self
  end

  def push r
    r = Row[r]
    r._header = @header
    # puts r.inspect(:super)
    @rows.push r
    self
  end
  alias :<< :push

  def unshift r
    r = Row[r]
    r._header = @header
    @rows.unshift r
    self
  end
  
  def pop   ; @rows.pop   ; end
  def shift ; @rows.shift ; end
  
  def size; @rows.size; end

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


class Row
  include Enumerable
  
  attr_reader :header, :data, :header_version
  attr_accessor :file_name, :line_number

  def inspect mode = nil
    case mode
    when :super
      super()
    else
      to_h.inspect
    end
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
      raise TypeError
    end
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
      raise TypeError
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

##############################

class Format < Struct.new(:mod, :parser, :formatter, :coerce, :name)
  def initialize *args
    super
    self.name ||= mod.name.to_sym
    self.formatter ||= DEFAULT_FORMATTER
  end
  
  def parse v, fmt = nil
    case v
    when mod, nil
      v
    else
      parser.call(v, fmt)
    end
  rescue
    nil
  end
  
  def format v, fmt = nil
    formatter.call(v, fmt)
  end

  DEFAULT_FORMATTER = Proc.new do | v, fmt |
    fmt ? (fmt % v) : v.to_s
  end
end

class Formatter
  attr_reader :formats
  
  def initialize
    @format_for = { }
    @formats = [ ]
  end

  def [] x
    @format_for[x] or raise ArgumentError
  end
  
  def add! format
    @format_for[format.mod] = @format_for[format.name] = format
    @formats << format
    self
  end

  def parse v, fmt = nil
    @formats.each do | f |
      # ap(v: v, f: f)
      begin
        case v
        when f.mod
          return v
        else
          parsed = f.parse(v, fmt) and return parsed
        end
      rescue => e
        ap(e: e, backtrace: e.backtrace)
        nil
      end
    end
    nil
  end

  DEFAULT = Formatter.new
  [
    [::Integer,
      Proc.new {|v, fmt| Integer(v)}
    ],
    [::BigDecimal,
      Proc.new {|v, fmt| BigDecimal(v)},
    ],
    [::Rational,
      Proc.new do |v, fmt|
        ((v =~ %r{^[-+]?\d+/\d+} && Rational(v)) rescue nil) or
          (Float(v) rescue nil)
      end,
    ],
    [::Float,
      Proc.new {|v, fmt| Float(v)}
    ],
    [::Time,
      Proc.new do |v, fmt|
        case v
        when Numeric
          Time.at(v)
        else
          Time.parse(v)
        end
      end,
      Proc.new do |v, fmt|
        fmt ? v.strftime(fmt) : v.to_s
      end,
    ],
    [::Date,
      Proc.new do |v, fmt|
        (Date.parse(v) rescue nil) or
          Format[::Time].parse(v, fmt).to_date
      end,
      Proc.new do |v, fmt|
        fmt ? v.to_time.strftime(fmt) : v.to_s
      end,
    ],
    [::Symbol,
      Proc.new {|v, fmt| c.to_sym}
    ],
    [::String,
      Proc.new {|v, fmt| c.to_s}
    ],
  ].each do | args |
    Formatter::DEFAULT.add!(Format::new(*args))
  end
end

######################################################

class HeaderOut
  include Xform
  def call input, env
    output = Table.new(input.header.dup)
    output << input.header.columns
    input.each do | row |
      output << row.dup
    end
    output
  end
end

######################################################

class Format
  def call input, env
    output = input.new
    header = output.header = input.header.new
    
    input.each do | r |
      new_r = { }
      r.each do | c, v |
        v = c.format(v)
        new_r[c] = v.nil? ? nil : v.to_s
      end
      output << new_r
    end

    ComputeMeta.new.call(output, env)
  end
end

######################################################

class Main
  include Xform
  
  def run! argv
    ints = (-100  .. 100).to_a
    strs = ("aaa" .. "zzz").to_a
    vals = (1 .. 200).map{|x| "#{x}%"}

    header = Header.new([:a, :b, :b, :"X %"])
    table = Table.new([], header)
    10.times do | i |
      table << [
        ints.sample,
        (i % 3).zero? ? strs.sample + " " : strs.sample,
        (i % 2).zero? ? nil : i / 10.0,
        vals.sample,
      ].map(&:to_s)
    end
    # table << header.map{|_c, _v| nil}
    
    ap(header: header)
    ap(table: table)
    if false
      ap(table[0])
      ap(table[1][:a])
      ap(table[1][:b])
      ap(table[0].to_a)
      ap(table[0].to_h)
      ap(table.map(&:to_a))
    end
    
    env = { }

    (Pipeline.new >> CSVOut >> IOOut).call(table, env)
    
    (Pipeline.new >> Quote >> EmptyToNull >> CalculateMeta >> MarkdownOut >> IOOut).call(table, env)

    table = (Pipeline.new >> Strip >> EmptyToNull).call(table, env)
    
    #################################

    (Pipeline.new >> CSVOut >> IOOut).call(table, env)
    # pp(env: env)

    (Pipeline.new >> CalculateMeta >> MetaTable >> CSVOut >> IOOut).call(table, env)
    # pp(env: env)

    (Pipeline.new >> CalculateMeta >> MarkdownOut >> IOOut.new(["tmp/table.md"]) >> IOOut).call(table, env)

    (Pipeline.new >> CalculateMeta >> MetaTable >> MarkdownOut >> IOOut.new(["tmp/metatable.md"]) >> IOOut).call(table, env)
    # pp(env: env)
    
    (Pipeline.new >> CalculateMeta >> MetaTable >> MetaTable >> MetaTable >> MarkdownOut >> IOOut).call(table, env)
    pp(env: env)

    #################################
    
    formatter = Formatter::DEFAULT
    v1 = "123412.234"
    v2 = formatter.parse(v1)
    ap(v1: v1, v2: v2, v2_class: v2.class)
    # binding.pry
    exit!
  end
end

Main.new.run!(ARGV)

end
