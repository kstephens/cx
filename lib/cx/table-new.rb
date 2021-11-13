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
require 'cx/xform'
CX::Xform.require_all!
require 'cx/test'
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

class Main
  include Xform, Test

  def run! argv
    begin
      _run! argv
    rescue SystemStackError => e
      puts e.backtrace.join("\n\t")
        .sub("\n\t", ": #{e}#{e.class ? " (#{e.class})" : ''}\n\t")
      raise e
    end
  end

  def _run! argv
    (Pipeline.new >> CalculateMeta >> Grep.new(["a:-8"]) >> HeaderOut >> CSVOut >> IOOut).call(make_table, env = {})
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
