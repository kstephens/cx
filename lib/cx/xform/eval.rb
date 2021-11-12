# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class Eval
      include Xform
      # :COMMAND:
      # Eval:
      #   name: html-
      #   aliases: html
      #   synopsis: Evaluates Ruby code for each row.
      #   args: []
      #   opts:
      def call input, env
        code = args.map do | arg |
          case arg
          when /^@(.*)/
            File.read($1)
          else
            arg
          end
        end.join(" ;\n")
        
        fn = "Proc.new do \n #{code} \nend\n"
        fn = eval(fn)
        
        ec = RowContext.new
        ec.input = input
        ec.env = env
        ec.header = input.header
        
        input.select! do | r |
          catch(:skip!) do
            ec.row = r
            ec.instance_eval(&fn)
            :keep!
          end # throw is false
        end
        input
      end
    end
  
    class RowContext < ::BasicObject
      attr_accessor :row, :input, :env, :header
      def _ ; self ; end # Shorthand

      def __col name
        unless col = @header[name]
          col = @header.add_column!(Column.new(name))
        end
        col
      end
      
      def __col_fn sel
        case
        when @row.respond_to?(sel)
          lambda do |*args, &blk|
            @row.send(sel, *args, &blk)
          end
        when /^(\w+)$/.match(sel.to_s)
          col = __col($1)
          ::PP::pp(get_col: col, sel: sel)
          ::Kernel.lambda do |*_args|
            # ::Kernel.puts({_args: _args}.inspect) unless _args.empty?
            @row[col]
          end
        when /^(\w+)=$/.match(sel.to_s)
          col = __col($1)
          ::PP::pp(set_col: col, sel: sel)
          ::Kernel.lambda do |v|
            # col.col_type!(v)
            @row[col] = v
          end
        else
          ::Proc.new do | *args, &blk |
            raise "Undefined method #{sel} in row #{@row.inspect}"
          end
        end
      end
      
      def next!
        ::Kernel.throw(:skip!, false)
      end

      def method_missing sel, *args, &blk
        sel = sel.to_sym
        fn = __col_fn(sel)
        __define_singleton_method(sel, &fn)
        fn.call(*args, &blk)
      end

      def __define_singleton_method sel, &blk
        m = ::Object.instance_method(:define_singleton_method)
        m.bind(self).call(sel, &blk) # use #bind_call?
        self
      end
    end
  end
end
