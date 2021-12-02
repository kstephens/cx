# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx/meta'
require 'cx/type'

module CX
  RSpec.describe Meta do
    include CX::Test
    subject { Meta.new }
    [ :size, :value ].each do | meth |
      eval <<"END"

    describe "min_max_#{meth}!" do
      it "works" do
        expect(subject.min_#{meth}) .to eq(nil)
        expect(subject.max_#{meth}) .to eq(nil)

        subject.min_max_#{meth}! 5
        expect(subject.min_#{meth}) .to eq(5)
        expect(subject.max_#{meth}) .to eq(5)

        subject.min_max_#{meth}! nil
        expect(subject.min_#{meth}) .to eq(5)
        expect(subject.max_#{meth}) .to eq(5)

        subject.min_max_#{meth}! 10
        expect(subject.min_#{meth}) .to eq(5)
        expect(subject.max_#{meth}) .to eq(10)
        
        subject.min_max_#{meth}! 0
        expect(subject.min_#{meth}) .to eq(0)
        expect(subject.max_#{meth}) .to eq(10)
      end
    end
END
    end
    
    describe "type!" do
      it "works" do
        expect(subject.types) .to eq(Set.new)

        subject.type! Integer
        expect(subject.types) .to eq(Set.new([Integer]))

        subject.type! Float
        expect(subject.types) .to eq(Set.new([Integer,Float]))
      end
    end

    describe "type" do
      it "works" do
        expect(subject.type) .to eq(nil)
        expect(subject.type_) .to eq(nil)

        subject.type = Integer
        expect(subject.type) .to eq(Integer)
        expect(subject.type_) .to eq(Integer)

        subject.type = :Integer
        expect(subject.type) .to eq(Integer)
        expect(subject.type_) .to eq(Integer)
      end
    end

    describe "type_inferred" do
      it "works" do
        expect(subject.type_inferred) .to eq(nil)
        expect(subject.type_) .to eq(nil)
        
        subject.type_inferred = Integer
        expect(subject.type_inferred) .to eq(Integer)
        expect(subject.type_) .to eq(Integer)

        subject.type_inferred = :Integer
        expect(subject.type) .to eq(nil)
        expect(subject.type_) .to eq(Integer)

        subject.type = :Float
        expect(subject.type) .to eq(Float)
        expect(subject.type_) .to eq(Float)
      end
    end

    describe "type_object" do
      it "works" do
        expect(subject.type_object) .to eq(nil)

        subject.type_inferred = Integer
        expect(subject.type_object) .to eq(Type[:Integer])

        subject.type = Float
        expect(subject.type_object) .to eq(Type[Float])
      end
    end
  end
end
