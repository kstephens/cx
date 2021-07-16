# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

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

require 'date'
require 'time'
require 'bigdecimal'
require 'csv'
require 'awesome_print'

class Column
  attr_reader :name, :index, :order, :meta, :header, :to_s
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

  def inspect mode = nil
    case mode
    when :super
      super()
    else
      to_sym.inspect
    end
  end
end

class Header
  include Enumerable
  attr_reader :columns, :meta

  def initialize cols = nil
    @version = 0
    @columns = [ ]
    @to_column = { }
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
      @to_column[k.to_sym]
    else
      raise TypError
    end
  end

  def first ; @columns.first ; end
  def last  ; @columns.last  ; end
  
  def new ; dup.deepen! ; end
  def deepen!
    @to_column = { }
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
    @to_column[name] = c
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
    new_name = available_name(c, name)
    c._name = new_name
    @to_column[new_name] = c
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
    when Hash
      Row.new(x, self)
    when Array
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
    self
  end
  
  def _header= h
    @header = h
    self
  end
  
  def each &blk
    @header.each do |c|
      yield _get(c)
    end
  end
  
  def each_with_col &blk
    @header.each do |c|
      yield _get(c), c
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
    out.write(to_a.map(&:to_s) * '')
    nil
  end

end

##############################

class Meta
  ATTRS =
    [
      [:name,       type: String],
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
    @types = Set.new
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
    @type_inferred = nil
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
      header << Column.new(name).tap{|c| c.meta.update(opts)}
    end
    header[:min_value].meta.type =
      header[:max_value].meta.type =
      self.type
    Table.new([], header)
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

###########################################

module Boolean
  ::TrueClass.include self
  ::FalseClass.include self
end  

class Type < Struct.new(:mod, :coerer, :format)
  def coerce v
    case v
    when mod, nil
      v
    else
      coercer.call(v)
    end
  rescue
    nil
  end

  def self.add! *args
    @@types << new(*args)
    self
  end
  @@types = [ ]

  [
    [::BigDecimal,
      Proc.new{|v| v.to_bd},
    ],
    [::Float,
      Proc.new{|v| v.to_f},
    ],
    [::Integer,
      Proc.new{|v| v.to_i},
    ],
    [::Time,
      Proc.new do |v|
        case v
        when Numeric          
          Time.at(v.to_f) rescue nil
        else
          (format.parse(v) rescue nil) or
            (Time.parse(v) rescue nil)
        end
      end,
    ],
    [::Date,
      Proc.new do |v|
        case v
        when Numeric          
          Time.at(v.to_f).to_date rescue nil
        else
          (format.parse(v) rescue nil) or
            (Date.parse(v) rescue nil)
        end
      end
    ],
    [::Symbol,
      Proc.new{|v| v.to_sym},
    ],
    [::String,
      Proc.new{|v| v.to_s},
    ],
    [::Boolean,
      Proc.new do | v |
        case v
        when nil
          false
        when Numeric
          ! v.zero?
        when String
          v =~ /t/i ? true : false
        end
      end
    ],
    [::Object,
      Proc.new{|v| v},
    ],
  ].each do | args |
    add!(*args)
  end
end

class TypeInference
  def initialize
    @formatter ||= Formatter::DEFAULT
    @parse_string = true
  end
  
  def call input, env
    input.each_row_col_val do | r, c, v |
      process_value!(r, c, v)
    end
    input
  end

  def process_value! r, c, v
    unless (parsed = infer_string_value(v, c)).nil?
      v_t = parsed.class
      r[c] = parsed if @parse_string && v_t != v.class
    else
      v_t = v.class
    end
    c.type = c.type_gcd_ignore_null(c.type, vt)
  end

  def infer_string_value v, c
    case v
    when String
      formatter.parse(v, c.format)
    else
      v
    end
  end
  
  def gcd_ignore_nil t1, t2, ignore = nil
    case
    when t1.nil? || t1 == NilClass
      t2
    when t2.nil? || t2 == NilClass
      t1
    else
      gcd(t1, t2, ignore)
    end
  end
  
  def gcd t1, t2, ignore = nil
    TYPE_LCMS[[t1, t2, ignore]] ||=
      begin
        _ignore = (ignore || EMPTY_Array) + IGNORE
        ((t1.ancestors - _ignore) & (t2.ancestors - _ignore))
          .reject{|m| m.class == Module}
          .sort
          .first
      end
  end

  TYPE_LCMS = { }
  EMPTY_Array = [].freeze
  IGNORE = [ NilClass ]
end

######################################################

class CalculateMeta
  def initialize
    @ti = TypeInference.new
  end
  
  def call input, env
    header = input.header
    
    m = header.meta
    m.clear!
    m.name = env[:input_name] || :__INPUT__
    m.min_size = 0
    m.max_size = input.size
    
    header.each do |c|
      m = c.meta
      m.clear!
      m.name = c.name
      m.index = c.index
      m.order = c.order
    end

    if block_given?
      yield lambda{|r| process_row!(header, r)}
    else
      input.each do | r |
        process_row! header, r
      end
    end

    input.header.each do | c |
      m = c.meta
      if m.type_inferred < Numeric || m.types.any?{|t| t < Numeric}
        m.align_inferred = :right
      end
    end
    
    input
  end

  def process_row! header, r
    m = header.meta
    r_blanks = r_nulls = 0
    header.each do | c |
      v = r[c]
      # ap(c: c, v: v)
      m.type!(v.class)
      case process_value!(r, c, v)
      when :blank
        r_blanks += 1
      when :null
        r_nulls += 1
      end
      # ap(c_meta: c.meta)
    end
    m.blanks += 1 if r_blanks == header.size
    m.nulls  += 1 if r_nulls  == header.size
    self
  end
  
  def process_value! r, c, v
    m = c.meta
    m.type!(v.class)
    m.type_inferred = @ti.gcd_ignore_nil(m.type_inferred, v.class)
    case v
    when nil
      m.nulls += 1
      :null
    else
      m.min_max_value! v
      str = v.to_s # TODO: c.format_as_string(v)
      m.min_max_size! str.size
      if str.empty?
        m.blanks += 1
        :blank
      end
    end
  end
end

######################################################

class MetaTable
  def call input, env
    output = input.header.meta.table
    output << input.header.meta.to_h
    input.header.each do | c |
      output << c.meta.to_h
    end
    CalculateMeta.new.call(output, env)
  end
end

#######################################

class Pipe
  attr_accessor :opts
  
  def initialize *args
    @opts = {}
    @apps = [ ]
  end
  def debug? ; false ; end
end

module Pipe::Format
end

module Pipe::LineOut
  include Pipe::Format
  def output
    @output ||=
      Table.new.tap do |t|
        t.header = Header.new << Column.new(:_LINE_).tap{|c| c.meta.type = ::String}
      end
  end
end


class Pipeline
  attr_accessor :apps
  def initialize *args
    @apps = [ ]
  end
  
  def << app
    @apps << app
    self
  end

  def call table, env
    @apps.inject(table) do |t, app|
      app.call(table, env)
    end
  end
end

class CSVOut < Pipe
  include Pipe::LineOut
  attr_accessor :col_sep, :multi_sep
  
  def initialize *args
    self.multi_sep ||= ';'
  end
  
  def call input, env
    output << line(input.header.map(&:to_s))
    input.each do | r |
      output << line(r)
    end
    env[:content_type] = 'text/csv' # according to RFC 4180.
    output
  end
  
  def line r
    [ CSV.generate_line(r.to_a.map{|v| format(v)}) ]
  end
  
  def format v
    case v
    when nil
      nil
    when Enumerable
      v.map{|e| format(e).to_s} * multi_sep
    else
      v.to_s
    end
  end
end

######################################################
# Refactored from MarkdownOut

class Align < Pipe
  include Pipe::Format
  
  def call input, env
    raise "TODO"
  end

  def header! header, min_width = 5
    @header = header
    @c_mw = header.map do |c|
      m = c.meta
      [
        m.max_size || 0,
        m.name.to_s.size,
        min_width
      ].max
    end
    self
  end

  def format_row row, fill = nil
    @header.map do |c|
      format_col row[c.to_i].to_s, c, fill
    end
  end
  
  def format_col v, c, fill
    mw = @c_mw[c.to_i]
    case fill
    when String
      center = (align = c.meta.align_) == :center
      v = fill * mw
      v[0]  = ':' if center || align == :left
      v[-1] = ':' if center || align == :right
    when :header
      mw = - mw
      v = "%#{mw}s" % v
    else
      mw = c.meta.align_ == :right ? mw : - mw
      v = "%#{mw}s" % v
    end
    v
  end
end

class MarkdownOut < Pipe
  include Pipe::LineOut
  
  def call input, env
    title = opts[:title]
    header = input.header
    
    @align = Align.new.header!(header)
    
    output << format_row(header.map(&:to_s), :header)
    output << format_row(header.map{|_| '---'}, '-')
    input.each do | row |
      output << format_row(row)
    end
    output
  end

  def format_row row, fill = nil
    row = @align.format_row(row, fill)
    [ '| '.dup << (row * ' | ') << " |\n" ]
  end
end

######################################################

class Format
  def call input, env
    output = input.new
    header = output.header = input.header.new
    
    input.each do | r |
      new_r = { }
      r.each_col_val do | c, v |
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
  def run! argv
    ints = (-100  .. 100).to_a
    strs = ("aaa" .. "zzz").to_a

    header = Header.new([:a, :b, :b])
    table = Table.new([], header)
    10.times do | i |
      table << [
        ints.sample,
        strs.sample,
        (i % 2).zero? ? nil : i / 10.0,
      ]
    end
    table << [ nil, nil, nil ]
    
    ap(header: header)
    ap(table: table)
    if false
      ap(table[0])
      ap(table[1][:a])
      ap(table[1][:b])
      ap(table[0].to_a)
      ap(table[0].to_a)
      ap(table.map(&:to_a))
    end
    
    env = { }
    t = table

    csv = CSVOut.new.call(t, env)
    # ap(t: t.map(&:to_a))
    csv.write

    cm = CalculateMeta.new.call(t, env)
    # ap(cm: cm)

    # ap(t.header.map{|c| c.meta})
    mt = MetaTable.new.call(t, env)
    # ap(mt: mt)
    
    csv = CSVOut.new.call(mt, env)
    # ap(t: t.map(&:to_a))
    csv.write

    csv_2 = CSVOut.new.call(csv, env)
    # ap(t: t.map(&:to_a))
    csv_2.write

    MarkdownOut.new.call(t, env).write
    
    formatter = Formatter::DEFAULT
    v1 = "123412.234"
    v2 = formatter.parse(v1)
    ap(v1: v1, v2: v2, v2_class: v2.class)
    binding.pry
    exit!
  end
end

Main.new.run!(ARGV)

