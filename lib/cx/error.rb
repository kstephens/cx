# frozen_string_literal: true

module CX
  class Error < StandardError
    attr_accessor :reason, :cause, :data
    
    module Support
      def raise_ *args
        msg = exc = exc_cls = backtrace = nil
        args.each do | arg |
          case arg
          when Exception
            exc = arg
            msg ||= exc.message
            backtrace = exc.backtrace
          when Class
            exc_cls = arg
            msg ||= 'NO-MESSAGE'
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
        msg_ << "#{describe_self_for_error}"
        msg_ << " : " << msg.to_s if msg
        msg_ << " : #{exc.class} : #{exc.message}" if exc
        
        exc_to_raise = exc_cls.new(msg_)
        begin
          exc_to_raise.reason = msg rescue nil
          exc_to_raise.cause  = exc rescue nil
          exc_to_raise.data   = data_for_error rescue nil
        rescue
        end
        
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

      def describe_self_for_error
        self.class.to_s.sub(/^CX::/, '')
      end

      def data_for_error
        nil
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
