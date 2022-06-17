# frozen_string_literal: true

require 'pp'

module CX
  module PPSafe
  extend self
  def pp *args
    M.synchronize do
      $stderr.write "#{Module === self ? self : self.class} #{'%x' % self.object_id} : "
      ::PP.pp(*args, $stderr)
    end
  end
  def pps *args
    ::PP.pp(*args, String.new).chomp
  end
  def ppss expr
    pps(expr).strip
  end
  def puts *args
    M.synchronize { $stderr.puts(*args) }
  end
  M = Mutex.new
end

  module Timing
    def with_timing h_ = nil
      h = h_ || { }
      h[:t0] = time_now
      begin
        result = yield h
        h_ && h_[:result] = result
        result
      ensure
        h[:elapsed_ms] = (((h[:t1] = time_now) - h[:t0]) * 1000).to_i
      end
    end
    def time_now
      Time.now
    end
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

class ::Array
  include CX::DestructiveEach
end

class RecurLimit
  def initialize
    @recur_level = 0
    @recur_limit ||= 1000
  end
  
  def call max = 1000
    raise ArgumentError unless block_given?
    @recur_level ||= 0
    begin
      @recur_level += 1
      binding.pry if @recur_level > (max || @recur_limit)
      yield
    ensure
      @recur_level -= 1
    end
  end
end

######################################

  module Rx
    def glob_to_rx str, opts = Empty_Hash
      rx = String.new
      until str.empty?
        rx <<
        case str
        when /^\\./
          $&
        when /^[.|{}()^$]/
          '\\' + $&
        when /^\*\*/
          '.*'
        when /^\*/
          opts[:file] ? '[^/]*' : '.*'
        when /^\?/
          opts[:file] ? '[^/]'  : '.'
        when /^./m
          $&
        else
          raise_ "glob_to_rx: #{str}"
        end
        str = $'
      end
      rx
    end
    Empty_Hash = { }.freeze
  end
end


