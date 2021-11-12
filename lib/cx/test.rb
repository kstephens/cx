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
      100.times do | i |
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
      opts[:table] ||= make_table
      out = StringIO.new
      pipeline = Xform::Pipeline.new | Xform::CalculateMeta | pipeline | Xform::HeaderOut | Xform::CSVOut | Xform::IOOut.new([out]) | Xform::IOOut.new(["tmp/last-pipeline"])
      pipeline.call(opts[:table], opts[:env])
      out.string
    end
    
    def assert_pipeline pipeline, expected, opts = {}
        expect(run_pipeline(pipeline, opts))
          .to eq(expected)
    end
    
    extend self
  end
end
