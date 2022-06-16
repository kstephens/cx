# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'
require 'cx/io_buffer'

module CX
  module Xform
    module StructuredIn
      include InputFormat, Xform
      
      def call input, env
        cols = { }
        inds = Hash.new{|h,k| h[k] = (0..k).to_a}
        input_str = input.flat_map(&:to_a) * ''
        input = nil
        rows = parse(input_str, env).map do | row |
          cols.update(Hash[row.keys.zip(inds[row.size])])
          row.values_at(*cols.keys)
        end
        input_str = nil
        output = Table.new(rows, Header.new(cols.keys))
        output
      end

      def parse input, env
        raise_ ArgumentError, "#{self}#parse : not implemented"
      end
    end

    module StructuredOut
      include RecordOutBase, SelectColumns, Xform

      def call input, env
        output = make_output
        out = IOBuffer.new(lambda {|line| output << [ line ]})

        row_sep = nil
        out << seq_delim[0].to_s
        fn = row_fn input
        input.each do | row | # each_shift
          out << row_sep.to_s if row_sep
          out << newline
          out << line(fn.call(row))
          row_sep = self.row_sep
        end
        out << (newline + seq_delim[1].to_s + newline)
        if x = content_type
          env[:content_type] = x
        end
        
        out.flush
        output
      end

      def row_mode? ; opts[:mode] == 'row' ; end
      
      def newline
        "\n"
      end
  
      def row_fn input
        if row_mode?
          fn = proc do | row |
            row.to_a
          end
        else
          fn = proc do | row |
            row.to_h
          end
        end
        fn
      end
  
      def content_type ; nil ; end
      def seq_delim
        @seq_delim ||= make_delim opts[:seq_delim]
      end
      def row_delim
        @row_delim ||= make_delim opts[:row_delim]
      end
      def make_delim cfg
        cfg ? cfg.to_s.gsub(/\s/, '').split('', 2).map(&:to_s) : [nil, nil]
      end
      def row_sep
        opts[:row_sep]
      end
    end
  end
end

