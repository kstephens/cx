# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/table'
require 'cx/xform/header'
require 'cx/xform/pipeline'
require 'stringio'

module CX
  module Test
    def make_table size = 100
      ints = (-100  .. 100).to_a
      strs = ("aaa" .. "zzz").to_a
      vals = (1 .. 200).map{|x| "#{x}%"}
      rand = Random.new(12345678)
      header = Header.new([:id, :a, :b, :b, :"X %"])
      table = Table.new([], header)
      header[:id].meta.type = ::Integer
      header[:"X %"].meta.type = ::Numeric
      size.times do | i |
        table << [
          i + 1001,
          ints.sample(random: rand),
          (i % 3).zero? ? strs.sample(random: rand) + " " : strs.sample(random: rand),
          (i % 5).zero? ? nil : i / 2.5,
          vals.sample(random: rand),
        ].map(&:to_s)
      end
      table
    end
    
    def run_pipeline pipeline, opts = {}
      opts[:env] ||= {}
      table = nil
      
      out = StringIO.new
      output_format = opts[:output_format] || (Xform::Pipeline.new | Xform::HeaderOut | Xform::CsvOut)
      input_pipeline = Xform::Pipeline.new

      case
      when opts[:input_data]
        input_format = opts[:input_format] || Xform::CsvIn
        input_io = StringIO.new(opts[:input_data])
        input_pipeline =
          Xform::Pipeline.new |
          Xform::IoIn.new([input_io]) |
          input_format
        # binding.pry
      when opts[:table]
        table = opts[:table]
      else
        table = make_table(opts[:size] || 10)
      end
      
      pipeline =
        input_pipeline |
        Xform::CalculateMeta |
        (pipeline || Xform::Pipeline.new) |
        output_format |
        Xform::IoOut.new([out])
      pipeline.call(table, opts[:env])
      out.string.
        sub(/\A/, '|').
        gsub(/\n/, "|\n|").
        sub(/\|\Z/, '')
    end
    
    def assert_pipeline pipeline, *args
      # pp([:assert_pipeline, :args, args])
      expected = opts = nil
      case args.map(&:class)
      when [String, Hash]
        expected, opts = args
      when [String]
        expected = args.first
      when [Hash]
        opts = args.first
      else
        raise ArgumentError, args.inspect
      end
      
      actual = run_pipeline(pipeline, opts || {})
      if expected
        if actual != expected
          File.write("spec/last-pipeline.txt", actual)
        end
        expect(actual) .to eq(expected)
      else
        # puts actual
        # binding.pry
      end
      actual
    end
    
    extend self
  end
end
