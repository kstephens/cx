require 'cx'

module CX
  module TypedAccessor
    def attr_accessor_typed *attrs
      attrs.each do | (name, type) |
        attr_reader name
        attr_writer_typed name, Hash === type ? type[:type] : type
      end
      self
    end

    def attr_writer_typed name, type, target = self
      ivar = "@#{name}"
      expr = <<"END"

###################################################
### CX::TypedAccessor : #{target} #{name}

COERCER__#{name} = ::CX::TypedAccessor.coercer_for(#{type})
def #{name}= __X__
   #{ivar} = COERCER__#{name}.call(__X__)
   $stderr.puts "### #{self} #{target} #{name} #{type} : \#{__X__.inspect} => \#{#{ivar}.inspect}" if #{ivar}.class != __X__.class
end
alias :__#{name}= :#{name}=

###################################################

END
      $stderr.puts expr
      target.module_eval(expr)
    end
    
    def self.coercer_for type
      case
      when Array === type
        elem_type = COERCERS[type.first] ||= Proc.new{|x| x}
        array_coercer = lambda do | x |
          x.map(&elem_type)
        end
        COERCERS[type] ||= wrap_nil_check(array_coercer)
      else
        COERCERS[type] ||= Proc.new{|x| x}
      end
    end

    def self.wrap_nil_check coercer
      lambda do | x |
        x.nil? ? nil : coercer.call(x)
      end      
    end
    
    def self.wrap_identity_check type, coercer
      lambda do | x |
        unless type === x
          x = coercer.call(x) 
          raise "#{type} : expected #{type} : got #{x.class}" unless type === x
        end
        x
      end
    end

    COERCERS = {
      ::Integer => Proc.new {|x| x.to_i},
      ::Float   => Proc.new {|x| x.to_f},
      ::String  => Proc.new {|x| x.to_s},
      ::Symbol  => Proc.new {|x| x.to_s.to_sym},
      ::Module  => Proc.new {|x| ::Kernel.const_get(x.to_s)},
      ::Boolean => Proc.new do |x|
        case x
        when ::Boolean
          x
        when Integer
          x.zero? ? false : true
        when String
          !! x +~ /[ty1-9]/i
        else
          !! x
        end
      end,
    }.map{|type, coercer|
      [type, wrap_nil_check(wrap_identity_check(type, coercer))]
    }.to_h
  end
end
