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
require 'cx/table'

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
require 'cx/xform/grep'

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

######################################################

module CX
  module Xform
    class HeaderOut
      include Xform
      def call input, env
        output = Table.new([], input.header.dup, input.meta.dup)
        output << input.header.map(&:to_s)
        input.each do | row |
          output << row.dup
        end
        output
      end
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

    header = Header.new([:id, :a, :b, :b, :"X %"])
    table = Table.new([], header)
    header[:id].meta.type = ::Integer
    header[:"X %"].meta.type = ::Numeric
    100.times do | i |
      table << [
        i + 1001,
        ints.sample,
        (i % 3).zero? ? strs.sample + " " : strs.sample,
        (i % 5).zero? ? nil : i / 2.5,
        vals.sample,
      ].map(&:to_s)
    end
    table
  end

  def _run! argv
    (Pipeline.new >> CalculateMeta >> Grep.new(["a:8"]) >> HeaderOut >> CSVOut >> IOOut).call(make_table, env = {})
    (Pipeline.new >> CalculateMeta >> Grep.new(["a:!;8"]) >> HeaderOut >> CSVOut >> IOOut).call(make_table, env = {})
    # exit!
    
    (Pipeline.new >> CalculateMeta >> Region.new(["11..23"]) >> CSVOut >> IOOut).call(make_table, env = {})
    (Pipeline.new >> CalculateMeta >> Region.new(["11..23"]) >> HeaderOut >> CSVOut >> IOOut).call(make_table, env = {})
    # exit!
    (Pipeline.new >> CalculateMeta >> Region.new(["11..23"]) >> MetaTable >> CSVOut >> IOOut).call(make_table, env = {})
    (Pipeline.new >> CalculateMeta >> Region.new(["11..23"]) >> CalculateMeta >> MetaTable >> CSVOut >> IOOut).call(make_table, env = {})
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
