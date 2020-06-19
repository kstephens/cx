# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

module CX
  module PPSafe
  extend self
  def pp *args
    M.synchronize do
      $stderr.write "#{Module === self ? self : self.class} #{'%x' % self.object_id} : "
      PP.pp(*args, $stderr)
    end
  end
  def pps *args
    PP.pp(*args, String.new).chomp
  end
  def ppss expr
    pps(expr).strip
  end
  def puts *args
    M.synchronize { $stderr.puts(*args) }
  end
  M = Mutex.new
end

######################################

class ThreadSafe < BasicObject
  def initialize p
    @p = p
    @m = ::Mutex.new
  end
  def method_missing sel, *args, &blk
    # puts " ### Log #{sel.inspect} #{args.inspect}"
    if @m.owned?
      @p.send(sel, *args, &blk)
    else
      @m.synchronize do
        @p.send(sel, *args, &blk)
      end
    end
  end
end

module NumericBool
  extend self
  def bool x
    case x
    when Numeric
      x
    when true
      1
    when false
      0
    else
      x.to_i
    end
  end
end

######################################

module DestructiveEach
  def each_shift
    yield shift until empty?
  end
  def each_pop
    yield pop until empty?
  end
end

end

class ::Array
  include CX::DestructiveEach
end
