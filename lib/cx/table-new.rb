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
require 'cx/formatter'
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
require 'cx/xform/region'

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

class Xform::FormatX
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

    header = Header.new([:row_id, :a, :b, :b, :"X %"])
    table = Table.new([], header)
    100.times do | i |
      table << [
        i + 1,
        ints.sample,
        (i % 3).zero? ? strs.sample + " " : strs.sample,
        (i % 5).zero? ? nil : i / 10.0,
        vals.sample,
      ].map(&:to_s)
    end
    table
  end

  def _run! argv
    (Pipeline.new >> Region.new(["11..23"]) >> CSVOut >> IOOut).call(make_table, env = {})
    # exit!
    
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
