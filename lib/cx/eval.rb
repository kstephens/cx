# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Eval < Pipe
  include Pipe::Process
  def call input, env
    fn = "Proc.new do \n " + args.join(" ;\n") + "\nend\n"
    fn = eval(fn)
    ec = RowContext.new
    ec.input = input
    ec.env = env
    ec.header = input.header!
    input.select! do | r |
      catch(:skip!) do
        ec.row = r
        ec.instance_eval(&fn)
        :keep!
      end # throw is false
    end
    app.call(input, env)
  end
  
  class RowContext < BasicObject
    attr_accessor :row, :input, :env, :header
    def _ ; self ; end # Shorthand

    def __col name
      unless col = @header[name]
        col = @header.add_col!(name)
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
        col_i = __col($1).to_i
        ::Kernel.lambda do |*_args|
          # ::Kernel.puts({_args: _args}.inspect) unless _args.empty?
          @row[col_i]
        end
      when /^(\w+)=$/.match(sel.to_s)
        col = __col($1); col_i = col.to_i
        ::Kernel.lambda do |v|
          col.col_type!(v)
          @row[col_i] = v
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
