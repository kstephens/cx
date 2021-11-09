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
require 'set'
require 'pry'

class Column
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

module Boolean
  ::TrueClass.include self
  ::FalseClass.include self
end  

##############################

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

class Type < Struct.new(:mod, :converter, :coercer, :matches, :format, :name)
  def initialize *args
    super
    self.name = mod.name.to_sym
  end
  
  def convert v
    case v
    when mod, nil
      v
    else
      converter.call(self, v) rescue nil
    end
  end

  def coerce v
    case v
    when mod, nil
      v
    else
      if (vc = (converter.call(self, v) rescue nil)).nil?
        vc = matches.call(self, v)
        vc &&= converter.call(self, coercer.call(self, vc)) rescue nil
#        binding.pry if v.to_s =~ /^[a-z]{3}$/
      end
      vc
    end
  end

  def parse v
    case v
    when mod, nil
      v
    when String
      if vp = matches.call(self, v)
        # binding.pry if v =~ /^0\./
        vp = converter.call(self, vp) rescue nil
      end
      vp
    else
      nil
    end
  end
  
  def self.try_parse! v
    return v if v.nil?
    return v unless String === v
    @@types.each do | t |
      # binding.pry if v.to_s =~ /%$/
      cv = t.parse(v)
      # pp(v: v, t: t.mod, cv: cv) if cv
      return cv unless cv.nil?
    end
    nil
  end

  @@types = [ ]
  @@types_by_module = { }
  @@types_by_name = { }

  def self.[] x
    case x
    when Module
      @@types_by_module[x]
    when Symbol, String
      @@types_by_name[x.to_sym]
    end or raise ArgumentError, "unknown Type #{x.inspect}"
  end
  
  def self.add! *args
    type = new(*args)
    @@types << type
    @@types_by_module[type.mod] = type
    @@types_by_name[type.name] = type
    self
  end

  ANY  = Proc.new {|t, v| v}
  NONE = Proc.new {|t, v| nil}
  def self.matches rx
    lambda do | t, v |
      String === v && rx.match(v) ? $1 : nil
    end
  end
  
  FLOAT_RX = /^([-+]?(\d+\.\d*|\.\d+|\d+)([efg][-+]?\d+)?)$/i
  [
    [::Integer,
      Proc.new{|t, v| Integer(v)},
      Proc.new{|t, v| v.to_i },
      matches(/^([-+]?\d+)$/),
    ],
    [::Rational,
      Proc.new{|t, v| Rational(v)},
      Proc.new{|t, v| v.to_r },
      matches(%r{^([-+]?\d+/\d+)$}),
    ],
    [::BigDecimal,
      Proc.new{|t, v| BigDecimal(v) },
      Proc.new{|t, v| v.to_s },
      matches(FLOAT_RX),
    ],
    [::Float,
      Proc.new{|t, v| Float(v) },
      Proc.new{|t, v| v.to_f },
      matches(FLOAT_RX),
    ],
    [::Time,
      Proc.new do |t, v|
        case v
        when Numeric          
          Time.at(v.to_f)
        else
          (format.parse(v) rescue nil) or
            (Time.parse(v) rescue nil)
        end
      end,
      Proc.new {|t, v| v.to_i },
      matches(/^(\d\d\d\d-\d\d-\d\d[-T ]\d\d:\d\d:\d\d(\.\d+)?)$/i),
    ],
    [::Date,
      Proc.new do |t, v|
        case v
        when Numeric          
          Time.at(v.to_f).to_date
        else
          (format.parse(v) rescue nil) or
            (Date.parse(v) rescue nil)
        end
      end,
      Proc.new{|t, v| v.to_s },
      matches(/^(\d\d\d\d-\d\d-\d\d)$/),
    ],
    [::Boolean,
      Proc.new do | v |
        case v
        when nil
          false
        when Numeric
          ! v.zero?
        when String
          v =~ /^[t1-9]/i ? true : false
        end
      end,
      Proc.new{|t, v| v.to_s },
      matches(/^(true|false)$/i),
    ],
    [::String,
      Proc.new{|t, v| v.to_s },
      Proc.new{|t, v| v.to_s },
      ANY,
    ],
    [::Symbol,
      Proc.new{|t, v| v.to_sym },
      Proc.new{|t, v| v.to_s },
      NONE,
    ],
    [::Object,
      Proc.new{|t, v| v },
      Proc.new{|t, v| v },
      ANY,
    ],
  ].each do | args |
    add!(*args)
  end
end

class ArgvParser
  attr_accessor :argv, :args, :opts
  
  def call argv
    @argv = argv.map(&:dup)
    @args = @argv.map(&:dup)
    @opts = { }
    while arg = args.first
      case arg
      when /^--([-_a-z0-9]+)/
        set_opt! $1, true
        args.shift
      when /^--([-_a-z0-9]+)=(.*)/
        set_opt! $1, $2
        args.shift
      when '--'
        break
      else
        break
      end
    end
    {argv: argv, args: args, opts: opts}
  end
  
  def set_opt! key, val
    opts[key.gsub(/-/, '_').to_sym] = val
  end
end

module Transform
  attr_accessor :argv, :args, :opts
  
  def initialize *argv
    @argv = argv.map(&:dup)
    # @apps = [ ]
    initialize!
  end

  def initialize!
    parser = ArgvParser.new
    result = parser.call(argv)
    @argv = result.argv
    @args = result.args
    @opts = result.opts
    self
  end

  def debug? ; false ; end

  def >> app
    Pipeline.new >> app
  end

  def inspect mode = nil
    case mode
    when :super
      super()
    else
      "#<#{self.class} #{object_id}#{inspect_content}>"
    end
  end
  
  def inspect_content
    ''
  end
end

class Pipeline
  include Transform
  
  attr_accessor :apps
  def initialize *args
    @apps = [ ]
    super
  end
  
  def >> app
    app = app.new if app.respond_to?(:new)
    @apps << app
    self
  end

  def call table, env
    @apps.inject(table) do |table, app|
      app.call(table, env)
    end
  end

  def inspect_content
    " (#{@apps.map(&:inspect) * ' >> '})"
  end
end

module Transform::Format
  include Transform
end

module Transform::SelectColumns
  include Transform
  def initialize!
  end
end

class Strip
  include Transform
  
  def call input, env
    input.each_row_col_val do | r, c, v |
      if String === v
        r[c] = v.strip
      end
    end
    input
  end
end

class Quote
  include Transform
  
  def call input, env
    input.each_row_col_val do | r, c, v |
      if String === v and q = v.inspect and q.gsub(/^"|"$/, '').strip != v
        r[c] = q
      end
    end
    input
  end
end

class EmptyToNull
  include Transform
  
  def call input, env
    input.each_row_col_val do | r, c, v |
      if String === v && v.empty?
        r[c] = nil
      end
    end
    input
  end
end

module Transform::LineOut
  include Transform::Format
  
  attr_accessor :col_sep, :row_sep, :multi_sep
  
  def initialize *args
    @col_sep = ','
    @row_sep = "\n"
    @multi_sep = ';'
    super
  end
  
  def output
    @output ||=
      Table.new.header! Header.new << Column.new(:_LINE_).tap{|c| c.meta.type = ::String}
  end
  
  def format_value v
    case v
    when nil
      nil
    when Enumerable
      v.map{|e| format_value(e).to_s} * multi_sep
    else
      v.to_s
    end
  end
end

###################################

class TypeInference
  include Transform
  
  def initialize
    @formatter ||= Formatter::DEFAULT
    @parse_string = true
  end
  
  def call input, env
    #  binding.pry
    input.each_row_col_val do | r, c, v |
      vc, vt = infer_type(r, c, v)
      m = c.meta
      m.type_inferred = gcd_ignore_nil(m.type_inferred, vt)
    end
    input
  end

  def infer_type r, c, v
    #    binding.pry
    vc = v
    case
    when v.nil?
      vt = nil
    when ! (vc = Type.try_parse!(v)).nil?
      vt = vc.class
    #when ! (parsed = infer_string_value(v, c)).nil?
    #  vt = parsed.class
    #  vc = parsed if @parse_string && vt != v.class
    else
      vt = v.class
    end
    [vc, vt]
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
  include Transform
  
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
      m.name_ = c.name_
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
      if m.type_inferred && m.type_inferred < Numeric
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
      m.type!(v.class)
      case process_value!(r, c, v)
      when :blank
        r_blanks += 1
      when :null
        r_nulls += 1
      end
    end
    m.blanks += 1 if r_blanks == header.size
    m.nulls  += 1 if r_nulls  == header.size
    self
  end
  
  def process_value! r, c, v
    m = c.meta
    v, vt = @ti.infer_type r, c, v
    m.type!(vt || v.class)
    m.type_inferred = @ti.gcd_ignore_nil(m.type_inferred, vt)  
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
  include Transform
  def call input, env
    output = input.header.meta.table
    # output << input.header.meta.to_h
    input.header.each do | c |
      output << c.meta.to_h
    end
    CalculateMeta.new.call(output, env)
  end
end

######################################################

class HeaderOut
  include Transform
  def call input, env
    output = Table.new(input.header.dup)
    output << input.header.columns
    input.each do | row |
      output << row.dup
    end
    output
  end
end

#######################################

class CSVOut
  include Transform::LineOut
  def call input, env
    output << line(input.header.map(&:to_s))
    input.each do | r |
      output << line(r)
    end
    env[:content_type] = 'text/csv' # according to RFC 4180.
    output
  end
  
  def line r
    [ CSV.generate_line(r.to_a.map{|v| format_value(v)}) ]
  end
end

class IOOut
  include Transform
  
  def initialize *args
    @io = args[0] || $stdout
    super
  end
  
  def call input, env
    open(@io, "w") do | io |
      input.each do | r |
        r.each do | _c, v |
          io.write(v)
        end
      end
    end
    input
  end

  def open io, mode
    case io
    when IO
      yield io
    when String
      File.open(io.to_s, mode) do | io |
        yield io
      end
    else
      raise TypeError
    end
  end
end

######################################################
# Refactored from MarkdownOut

module Align
  def header! header, min_width = 5
    @header = header
    @c_mw = header.map do |c|
      m = c.meta
      [
        m.max_size || 0,
        c.name.size,
        min_width
      ].max
    end
    @c_fmt = Hash.new{|h,i| h[i] = "%#{i}s"}
    self
  end

  def align_row row, fill = nil
    @header.map do |c|
      align_col row[c.to_i].to_s, c, fill
    end
  end
  
  def align_col v, c, fill
    mw = @c_mw[c.to_i]
    case fill
    when :header
      mw = - mw
      v = @c_fmt[mw] % v
    when String
      center = (align = c.meta.align_) == :center
      v = fill * mw
      v[0]  = ':' if center || align == :left
      v[-1] = ':' if center || align == :right
    else
      mw = c.meta.align_ == :right ? mw : - mw
      v = @c_fmt[mw] % v
    end
    v
  end
end

class MarkdownOut
  include Transform::LineOut, Align
  
  def call input, env
    title = opts[:title]
    header!(input.header)
    output << format_row(input.header.map(&:to_s), :header)
    output << format_row(input.header.map{|_| '---'}, '-')
    input.each do | row |
      output << format_row(row)
    end
    env[:content_type] = 'text/markdown' # 2016 RFC7763 at IETF
    output
  end

  def format_row row, fill = nil
    row = row.map{|c, v| format_value(v)} unless fill == :header
    row = align_row(row, fill)
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
      ap(table[0].to_a)
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

    (Pipeline.new >> CalculateMeta >> MarkdownOut >> IOOut.new("tmp/table.md") >> IOOut).call(table, env)

    (Pipeline.new >> CalculateMeta >> MetaTable >> MarkdownOut >> IOOut.new("tmp/metatable.md") >> IOOut).call(table, env)
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

