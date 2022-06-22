# frozen_string_literal: true

module CX
  class VersionString
    include Comparable

    attr_reader :to_s, :to_a, :strs

    def hash ; to_s.hash ; end

    def self.[] x
      case x
      when nil, self
        x
      else
        new x
      end
    end

    def initialize str
      raise TypeError, "not a string" unless String === str
      @to_s = str.dup.freeze
      @strs, @to_a = [ ], [ ]
      s = str
      i = -1
      until s.empty?
        i += 1
        case s
        when /^(?:[[:alpha:]]+|[^[[:alpha:]]\d]+)/m
          @to_a[i] = $&
        when /^\d+/
          @to_a[i] = Integer($&.to_i)
        else
          raise ArgumentError, "#{self.class} : cannot parse #{str.inspect} : at #{s.inspect}"
        end
        @strs[i] = $&
        s = $'
      end
      @strs.freeze ; @to_a.freeze
      self
    end

    def <=> other
      to_a = other.to_a
      n = @to_a.size > to_a.size ? @to_a.size : to_a.size
      n.times do | i |
        a, b = @to_a[i], to_a[i]
        unless a.class == Integer && b.class == Integer
          a, b = @strs[i].to_s, to_a[i].to_s
        end
        unless (cmp = a <=> b).zero?
          return cmp
        end
      end
      0
    end

    def inspect deep = false
      deep ? super() : "#{self.class.name}[#{to_s.inspect}]"
    end
  end
end


