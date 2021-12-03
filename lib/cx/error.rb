# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

module CX
  class Error < StandardError
    attr_accessor :cause
    
    module Support
      def raise_ *args
        msg = exc = exc_cls = exc_message = backtrace = nil
        args.each do | arg |
          case arg
          when Class
            exc_cls = arg
            exc_message = 'NO-MESSAGE'
          when Exception
            exc = arg
            exc_message = exc.message
            backtrace = exc.backtrace
          when Array
            backtrace = arg
          else
            msg = arg.to_s
          end
        end
        
        msg ||= "NO-MESSAGE"
        backtrace ||= exc && exc.backtrace
        exc_cls ||= raise_cls
        
        msg_ = String.new
        msg_ << "#{inspect}"
        msg_ << " : " << msg.to_s if msg
        msg_ << " : #{exc.class} : #{exc.message}" if exc
        msg = msg_
        
        exc_to_raise = exc_cls.new(msg)
        
        if debug?
          pp(exc_to_raise: exc_to_raise, exc: exc, msg: msg, backtrace: backtrace && backtrace.reverse)
          binding.pry
        end
        
        if backtrace
          raise exc_to_raise, backtrace
        else
          raise exc_to_raise
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
        @@raise_cls || ::CX::Error
      end
      
      def self.raise_cls= x
        @@raise_cls = x
      end

      @@raise_cls = nil

    end
  end
end
