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
require 'cx/column'
require 'cx/header'
require 'cx/row'
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
require 'cx/xform/html'
require 'cx/xform/eval'

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
  def select! &blk
    @rows.select!(&blk)
    self
  end
  
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
    begin
      _run! argv
    rescue SystemStackError => e
      puts e.backtrace.join("\n\t")
        .sub("\n\t", ": #{e}#{e.class ? " (#{e.class})" : ''}\n\t")
      raise e
    end
  end

  def make_table size = 100
    ints = (-100  .. 100).to_a
    strs = ("aaa" .. "zzz").to_a
    vals = (1 .. 200).map{|x| "#{x}%"}

    header = Header.new([:a, :b, :b, :"X %"])
    table = Table.new([], header)
    100.times do | i |
      table << [
        ints.sample,
        (i % 3).zero? ? strs.sample + " " : strs.sample,
        (i % 5).zero? ? nil : i / 10.0,
        vals.sample,
      ].map(&:to_s)
    end
    table
  end

  def _run! argv
    (Pipeline.new >> CSVOut >> IOOut).call(make_table, env = {})
    
    (Pipeline.new >> Quote >> EmptyToNull >> CalculateMeta >> MarkdownOut >> IOOut).call(make_table, env = { })

    #################################

    (Pipeline.new >> CSVOut >> IOOut).call(make_table, env = {})
    # pp(env: env)

    (Pipeline.new >> CalculateMeta >> MetaTable >> CSVOut >> IOOut).call(make_table, env = {})
    # pp(env: env)

    (Pipeline.new >> CalculateMeta >> MarkdownOut >> IOOut.new(["tmp/table.md"]) >> IOOut).call(make_table, env = {})

    ################################################
    
    (Pipeline.new >> Strip >> EmptyToNull >> CalculateMeta >> HTMLOut >> IOOut.new(["tmp/table.html"])).
      call(make_table, env = {})

    (Pipeline.new >> Strip >> EmptyToNull >> CalculateMeta >> MetaTable >> HTMLOut >> IOOut.new(["tmp/metatable.html"])).
      call(make_table, env = {})
    
    (Pipeline.new >> Strip >> EmptyToNull >> CalculateMeta >> MetaTable >> MetaTable >> HTMLOut >> IOOut.new(["tmp/metametatable.html"])).
      call(make_table, env = {})
    
    (Pipeline.new >> Strip >> EmptyToNull >> CalculateMeta >> Eval.new(["_.foo = a + " " + b"]) >>
      HTMLOut >> IOOut.new(["tmp/table-2.html"])).
      call(make_table, env = {})
    ################################################

    (Pipeline.new >> Strip >> EmptyToNull >> MetaTable >> MarkdownOut >> IOOut.new(["tmp/metatable.md"]) >> IOOut).
      call(make_table, env = {})
    # pp(env: env)
    
    (Pipeline.new >> Strip >> EmptyToNull >> CalculateMeta >> MetaTable >> MetaTable >> MetaTable >> MarkdownOut >> IOOut).call(make_table, env = {})
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
