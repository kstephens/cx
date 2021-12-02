# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx/type'
require 'time'
require 'date'

module CX
  RSpec.describe Type do
    include CX::Test
    let(:values) do
      [
        nil,
        true,
        false,
        -2,
        -3,
        Rational("5/7"),
        Rational("-5/7"),
        11.13,
        -11.13,
        BigDecimal("17.23"),
        BigDecimal("-17.23"),
        Date.parse("2021-11-17"),
        Time.parse("2021-11-17T18:17:22.123-06:00"),
        "a-string",
        :a_symbol,
        [:an_array],
        {a_hash: 123},
      ]
    end
    let(:types) { Type.all }

    describe 'Type.parse' do
       it 'non-strings pass-through' do
        actual = values.map do |x|
          Type.parse(x)
        end
        expect(actual) .to eq(values)
       end
       
      it 'parses strings accoring to "best" type' do
        inputs = values.map(&:to_s)
        actual = inputs.map do |x|
          v = Type.parse(x)
          [x.class, stringify(x), v.class, stringify(v)]
        end
        assert_content "type_spec/parse-1", actual
      end
      
      it 'parses unanchored' do
        inputs = values.map(&:to_s)
        inputs = inputs.flat_map do |s|
          [ s, "A #{s} Z" ]
        end
        actual = inputs.map do |x|
          v = Type.parse(x, false)
          [x.class, stringify(x), v.class, stringify(v)]
        end
        assert_content "type_spec/parse-2", actual
      end
    end
    
    it "match" do
      strings = values.map(&:to_s)
      strings +=
        strings.map{|s| s + "XYZ"} +
        strings.map{|s| "AbC" + s } +
        strings.map{|s| "AbC" + "XYZ" }
      actual = do_values(strings) do | t, v |
        t.match(v)
      end
      assert_content "type_spec/match-1", actual
    end
    
    it "cast" do
      values_and_strings = values + values.map(&:to_s)
      actual = do_values(values_and_strings) do | t, v |
        t.cast(v)
      end
      assert_content "type_spec/cast-1", actual
    end
    
    it "coerce" do
      values_and_strings = values + values.map(&:to_s)
      actual = do_values(values_and_strings) do | t, v |
        t.coerce(v)
      end
      assert_content "type_spec/coerce-1", actual
    end

    describe 'add!' do
      it "Registers for Type.lookup" do
        # expect(fut(nil)) .to be_nil # ??? TODO
        expect(Type.all.first) .to be_a(Type)
      end
    end

    describe 'lookup' do
      def fut x; Type.lookup(x); end
      
      it 'resolves by Module, String, Symbol, nil, Type' do
        expect(fut(Type.all.first)) .to eq(Type.all.first)
        expect(fut(Integer))    .to be_a(Type)
        expect(fut(:Integer))   .to be_a(Type)
        expect(fut("Integer"))  .to be_a(Type)
        expect(fut(:integer))   .to be_a(Type)
        expect(fut("integer"))  .to be_a(Type)
      end
      
      it 'resolves ancestors' do
        boolean = fut(Boolean)
        expect(boolean) .to be_a(Type)
        expect(fut(Boolean)) .to eq(boolean)
        expect(fut(false.class)) .to eq(boolean)
        expect(fut(true.class)) .to eq(boolean)
      end
    end

    def do_values values = self.values
      actual = [ ]
      types.each do | t |
        values.each do | v |
          cv = yield t, v
          actual << [ v.class, stringify(v), :>>, t.name, :>>, cv.class, stringify(cv) ]
        end
      end
      actual
    end
  end
end
