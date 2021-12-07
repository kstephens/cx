# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/meta'

module CX
  module Xform
    module RecordBase
      include Xform
      attr_accessor :col_sep, :row_sep, :multi_sep
    
      def initialize!
        super
        @field_sep    = decode_string(opts.fetch(:field_sep,   ","))
        @record_sep   = decode_string(opts.fetch(:record_sep,  $/))
        @multi_sep    = decode_string(opts.fetch(:multi_sep,   ";"))
      end

      def decode_string s
        s = '"' + s.gsub(/["#]/){|m| '\\' + m[0]} + '"'
        eval(s)
      end
      
      def make_record_table cols = []
        cols = cols.map{|c| Column.new(c).tap{|c| c.meta.type = ::String}}
        Table.new([], Header.new(cols))
      end
    end

    module RecordIn
      include InputFormat, RecordBase
      
      def call input, env
        raise_ ArgumentError, "expected one input row" unless input.size == 1
        raise_ ArgumentError, "expected one input col" unless input.first.size == 1
        input_string = input[0][0].to_s
        rows = input_string.split(@record_sep, -1)
        rows.pop if rows[-1].empty?
        rows = rows.map!{|line| parse_record(line)}
        header = Header.
          new(rows.first ? rows.first.size : 0).
          each{|c| c.meta.type = ::String}
        output = Table.new(rows, header)
        output = MetaIn.new.call(output, env)
        output
      end

      def parse_record line
        raise Exception, line
      end
    end
    
    module RecordOut
      include OutputFormat, RecordBase
      
      def make_output
        make_record_table([:_RECORD_])
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
  end
end

