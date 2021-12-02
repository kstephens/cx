# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'date'
require 'time'
require 'bigdecimal'
require 'rational'
require 'set'
require 'cx/boolean'

module CX
  class Type < Struct.new(:mod, :caster, :coercer, :matcher, :parser, :formatter, :name, :to_s)
    
    def initialize *args
      super
      self.to_s = mod.name.downcase.freeze
      self.name = self.to_s.to_sym
      self.formatter ||= Proc.new{|t, v| v.to_s}
    end

    def match v, anchored = true
      case v
      when String
        if m = matcher.call(self, v)
          return nil if anchored && m != v
          m
        end
      end
    rescue
      nil
    end
    
    def parse v, anchored = true
      case v
      when nil, mod
        v
      when String
        if vp = match(v, anchored)
          return nil if anchored && vp != v
          vp = parser.call(self, vp)
        end
        vp
      end
    rescue
      nil
    end

    def self.parse v, anchored = true, types = @@types
      return v unless String === v
      types.find do | t |
        unless (cv = t.parse(v, anchored)).nil?
          return cv
        end
      end
      nil
    end

    def format v
      formatter.call(self, v)
    end
    
    def cast v
      case v
      when nil, mod
        v
      else
        coerce(v) || caster.call(self, v)
      end
    rescue
      nil
    end

    def cast_string str
      if pv = self.parse(v)
        return pv
      end
      @@types.each do | t2 |
        if pv = t2.parse(v) and cv = t.cast(v)
          return cv
        end
      end
      nil
    end
    
    def coerce v
      case v
      when nil, mod
        v
      when String
        case v = parse(v)
        when nil, mod
          v
        else
          coercer.call(self, v)
        end
      else
        coercer.call(self, v)
      end
    rescue
      nil
    end

    ##################################################
    
    @@types = [ ]
    @@types_by = { }
    @@types_by_cache = { }

    class << self
      def all
        @@types
      end

      def lookup x
        case x
        when Type
          x
        when Symbol, String
          @@types_by_cache[x]
        when Module
          type_by_module(x)
        end or raise ArgumentError, "unknown Type #{x.inspect}"
      end
      alias :[] :lookup

      def type_by_module mod
        case type = @@types_by_cache[mod]
        when false
          # Sentinel
          return nil
        when nil
          # Search below
        else
          return type
        end

        type = @@types_by[mod]

        unless type
          type = @@types.find do | type |
            mod <= type.mod
          end
        end

        if type
          # puts "Found: #{type.mod} for #{mod}"
          tmp_type = Type.new(mod)
          add_types_by! tmp_type, @@types_by_cache
        else
          # Sentinel
          @@types_by_cache[mod] = false
        end
        type
      end

      def add_types_by! type, out
        h = { }
        h[type.mod] = type
        [ type.mod.to_s, type.to_s, type.name.to_s ].each do | s |
          sd = s.downcase
          h[s] = h[s.to_sym] = h[sd] = h[sd.to_sym] = type
        end
        # puts "add_types_by! #{type.mod} : #{h.keys.inspect}"
        out.update(h)
        type
      end

      def add! *args
        type = new(*args)
        @@types << type
        add_types_by! type, @@types_by
        add_types_by! type, @@types_by_cache
        self
      end
    end
    
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    
    ANY  = Proc.new {|t, v| v}
    NONE = Proc.new {|t, v| nil}
    def self.matches rx
      lambda do | t, v |
        rx.match(v){|m| m[0]}
      end
    end
    
    def self.b2i x
      case x
      when true
        1
      when false
        0
      else
        x
      end
    end

    Integer_rx    = %r{[-+]?\d+}
    Rational_rx   = %r{[-+]?\d+/\d+}
    Float_rx      = %r{[-+]?(\d+\.\d*|\.\d+|\d+)([efg][-+]?\d+)?}i
    Date_rx       = %r{(\d\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])}
    TimeOfDay_rx  = %r{([01]\d|2[0-3]):([0-5]\d):([0-5]\d|60)(\.\d+)?}
    TimeZone_rx   = %r{[-+]\d\d:?\d\d|Z$}
    Time_rx       = %r{((\d\d\d\d)-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01]))[-tT ]\d\d:\d\d:\d\d(\.\d+)? ?([-+]\d\d:?\d\d|Z)?}
    
    # These are in a specific order:
    [
      [::Integer,
        Proc.new{|t, v|
          case v
          when String
            case v
            when Integer_RX
              Integer(v)
            when Float_RX
              Integer(BigDecimal(v))
            end
          end
        },
        Proc.new{|t, v|
          case v
          when Numeric
            Integer(v)
          when Boolean
            b2i(v)
          when Time
            v.to_i
          end
        },
        matches(Integer_rx),
        Proc.new{|t, v|
          Integer(v)
        },
      ],
      [::Rational,
        Proc.new{|t, v|
          case v
          when Numeric
            Rational(v)
          when String
            case v
            when Integer_RX
              Rational(v)
            when Float_RX
              Rational(BigDecimal(v))
            when Rational_RX
              Rational(v)
            end
          when Boolean
            b2i(v)
          end
        },
        Proc.new{|t, v|
          case v
          when Float
            Rational(v.to_s)
            # Rational(123.23) => (8671540345013535/70368744177664
            # Rational((123.23).to_s) => (12323/100)
          when Numeric
            Rational(v)
          end
        },
        matches(Rational_rx),
        Proc.new{|t, v|
          Rational(case v
                   when Rational_rx
                     v
                   when Integer_rx
                     Integer(v)
                   when Float_rx
                     BigDecimal(v)
                   end)
        },
      ],
      [::BigDecimal,
        Proc.new{|t, v| BigDecimal(v) },
        Proc.new{|t, v|
          case v
          when Float
            BigDecimal(v.to_s)
          when Rational
            BigDecimal(v.to_f.to_s)
          when Numeric
            BigDecimal(v)
          end
        },
        matches(Float_rx),
        Proc.new{|t, v|
          BigDecimal(v)
        },
      ],
      [::Float,
        Proc.new{|t, v| Float(v) },
        Proc.new{|t, v|
          case v
          when Rational
            v.to_f
          when Numeric
            Float(v)
          when Time
            v.to_f
          end
        },
        matches(Float_rx),
        Proc.new{|t, v|
          # binding.pry
          Float(v)
        },
      ],
      [::Time,
        Proc.new {|t, v|
          case v
          when Date
            v.to_time
          else
            Time.parse(t.match(v))
          end
        },
        Proc.new {|t, v|
          case v
          when Integer
            Time.at(v)
          when Numeric          
            Time.at(v.to_f)
          end
        },
        matches(Time_rx),
        Proc.new {|t, v|
          Time.parse(v)
        },
        Proc.new {|t, v| v.iso8601(6)}
      ],
      [::Date,
        Proc.new {|t, v|
          case v
          when Time
            v.to_date
          end
        },
        Proc.new {|t, v|
          case v
          when Time
            v.to_date
          when Numeric          
            Time.at(v.to_f).to_date
          end
        },
        matches(Date_rx),
        Proc.new {|t, v|
          # binding.pry if v =~ /^2021-/
          case v
          when Date_rx
            Date.parse(v)
          when Time_rx
            Time.parse(v).to_date
          end
        },
      ],
      [::Boolean,
        Proc.new do | v |
          case v
          when Numeric
            ! v.zero?
          end
        end,
        Proc.new{|t, v|
          case v
          when Numeric
            ! v.zero?
          end
        },
        matches(/^(true|t|-?[1-9]\d*|false|f|0+)$/i),
        Proc.new {|t, v|
          case v
          when /^(true|t|-?[1-9]\d*)$/i
            true
          when /^(false|f|0+)$/i
            false
          end
        },
      ],
      [::String,
        Proc.new{|t, v| v.to_s },
        Proc.new{|t, v| v.to_s },
        ANY,
        Proc.new{|t, v| v.to_s },
      ],
      [::Symbol,
        Proc.new{|t, v|
          String === v ? v.to_sym : nil
        },
        Proc.new{|t, v| nil },
        ANY,
        Proc.new{|t, v|
          String === v ? v.to_sym : nil
        },
      ],
      [::Object,
        Proc.new{|t, v| v },
        Proc.new{|t, v| v },
        ANY,
        Proc.new{|t, v| v },
        Proc.new{|t, v| v.inspect},
      ],
      [::Numeric,
        Proc.new{|t, v| Numeric === v ? v : nil},
        Proc.new{|t, v| Numeric === v ? v : nil},
        NONE,
        Proc.new{|t, v| v },
      ],
    ].each do | args |
      add!(*args)
    end
  end
end
