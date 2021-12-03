# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

module CX
  class Error < StandardError
    attr_accessor :cause
    
    module Support
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

    end
  end
end
