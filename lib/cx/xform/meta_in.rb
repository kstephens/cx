# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/xform/type_inference'

# :COMMAND:
# MetaIn:
#   aliases: [ -meta, types ]
#   synopsis: Calculates various column metadata from row data.
#   args: []
#   opts: {}

module CX
  module Xform
    class MetaIn
      include Xform
      def initialize
        super
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
          m.type  = nil if opts[:clear_type]
          m.name  = c.name
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
          if m.type_inferred && m.type_inferred <= ::Numeric
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
  end
end

