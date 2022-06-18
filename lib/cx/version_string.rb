# frozen_string_literal: true

module CX
  class VersionString
    include Comparable

    attr_reader :strs, :nums, :to_s, :to_a

    def self.[] x
      case x
      when nil, self
        x
      when String
        new x
      else
        raise TypeError, "#{x.class}"
      end
    end

    def initialize str
      raise TypeError, "not a string" unless String === str
      @to_s = str.dup.freeze
      @strs, @nums, @to_a = [ ], [ ], [ ]
      i = -1
      until str.empty?
        i += 1
        @nums[i] = nil
        case str
        when /^[[:alpha:]]+/
        when /^[^[[:alpha:]]\d]+/m
        when /^\d+/
          @nums[i] = Integer($&.to_i)
        end
        @strs[i] = $&
        @to_a[i] = @nums[i] || @strs[i]
        str = $'
      end
      @strs.freeze ; @nums.freeze ; @to_a.freeze
      self
    end

    def <=> other
      return 1 if other.nil?
      raise TypeError, "#{other.inspect}" unless VersionString === other
      nums, strs = other.nums, other.strs
      n = [@strs.size, strs.size].max
      n.times do | i |
        a, b = @nums[i], nums[i]
        unless a && b && a.class == b.class
          a, b = @strs[i].to_s, strs[i].to_s
        end
        # pp(i: i, a: a, b: b)
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


