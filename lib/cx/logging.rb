# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'logger'
require 'cx/util'

module CX
  module Logging
    
  include PPSafe
  def self.log
    @@log ||= ThreadSafe.new(::Logger.new($stderr))
  end
  @@log = nil
  def log
    Logging.log # @_log ||= PrefixedLog.new(self, Logging.log)
  end
  
  class PrefixedLog < Object
    def initialize cntx, log
      @cntx, @log = cntx, log
    end
    [ :debug, :info, :warn, :error, :fatal ].each do | m |
      define_method(m) do | msg, *args, &blk |
        @log.send(m, "#{prefix} : #{msg}", *args, &blk)
      end
    end
    def prefix ; @cntx.inspect ; end
    def method_missing sel, *args, &blk
      @log.send(sel, *args, &blk)
    end
  end
  
  def puts *args
    $stderr.puts(*args)
    nil
  end
  def raise_ msg_ = nil, exc = nil
    msg = String.new
    msg << "#{inspect}"
    msg << " : " << msg_ if msg_
    msg << " : #{exc.inspect}" if exc
    if debug?
      pp(exc: exc, msg: msg, backtrace: exc && exc.backtrace.reverse)
      binding.pry
    end
    if exc
      raise raise_cls, msg, exc.backtrace
    else
      raise raise_cls, msg
    end
  end
  def reraise
    yield
  rescue raise_cls
    raise
  rescue => exc
    raise_ nil, exc
  end
  def raise_cls
    @@raise_cls || StandardError
  end
  def self.raise_cls= x
    @@raise_cls = x
  end
  @@raise_cls = nil
  class << self
    attr_accessor :debug
  end
  attr_accessor :debug
  def debug?
    @debug || Logging.debug
  end
end
end
