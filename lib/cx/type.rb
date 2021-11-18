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
  class Type < Struct.new(:mod, :caster, :coercer, :matcher, :formatter, :name)
    def initialize *args
      super
      self.name = mod.name.to_sym
      self.formatter ||= Proc.new{|t, v| v.to_s}
    end

    def cast v
      case v
      when nil, mod
        v
      else
        caster.call(self, v) rescue nil
      end
    end

    def coerce v
      case v
      when nil, mod
        v
      else
        coercer.call(self, v) rescue nil
      end
    end

    def match v
      case v
      when String
        matcher.call(self, v)
      end
    end
    
    def match_exact v
      case v
      when String
        s = matcher.call(self, v) and s.size == v.size and s
      end
    end
    
    def parse v
      case v
      when nil, mod
        v
      when String
        if vp = match(v)
          vp = coerce(vp)
        end
        vp
      else
        nil
      end
    end

    def format v
      formatter.call(self, v)
    end
    
    def self.try_parse! v, types = @@types
      return v if v.nil?
      return v unless String === v
      types.each do | t |
        # binding.pry if v.to_s =~ /%$/
        cv = t.parse(v)
        # pp(v: v, t: t.mod, cv: cv) if cv
        return cv unless cv.nil?
      end
      nil
    end

    @@types = [ ]
    @@types_by = { }

    def self.[] x
      case x
      when Module, Symbol, String
        @@types_by[x]
      end or raise ArgumentError, "unknown Type #{x.inspect}"
    end

    def self.add! *args
      type = new(*args)
      @@types << type
      @@types_by[type.mod] =
        @@types_by[type.name.to_sym] =
        @@types_by[type.name.downcase.to_sym] =
        @@types_by[type.name.to_s] =
        @@types_by[type.name.downcase.to_s] =
        type
      self
    end
    def self.all
      @@types
    end    

    ANY  = Proc.new {|t, v| v}
    NONE = Proc.new {|t, v| nil}
    def self.matches rx
      lambda do | t, v |
        rx.match(v) ? $1 : nil
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

    INTEGER_RX = /^([-+]?\d+)$/
    Rational_RX = %r{^([-+]?\d+/\d+)$}
    FLOAT_RX = /^([-+]?(\d+\.\d*|\.\d+|\d+)([efg][-+]?\d+)?)$/i
    # These are in a specific order:
    [
      [::Integer,
        Proc.new{|t, v| Integer(v)},
        Proc.new{|t, v|
          case v
          when Numeric
            Integer(v)
          when String
            case v
            when FLOAT_RX
              BigDecimal(v).to_i
            else
              Integer(v)
            end
          when Boolean
            b2i(v)
          when Time
            v.to_i
          end
        },
        matches(INTEGER_RX),
      ],
      [::Rational,
        Proc.new{|t, v| Rational(v)},
        Proc.new{|t, v|
          case v
          when Float
            Rational(v.to_s)
            # Rational(123.23) => (8671540345013535/70368744177664
            # Rational((123.23).to_s) => (12323/100)
          when Numeric
            Rational(v)
          when String
            Rational(case v
                     when Rational_RX
                       v
                     when INTEGER_RX
                       Integer(v)
                     when FLOAT_RX
                       BigDecimal(v)
                     else
                       v
                     end)
          end
        },
        matches(Rational_RX),
      ],
      [::BigDecimal,
        Proc.new{|t, v| BigDecimal(v) },
        Proc.new{|t, v|
          case v
          when Float
            BigDecimal(v.to_s)
          when Rational
            BigDecimal(v.to_f.to_s)
          when Numeric, String
            BigDecimal(v)
          end
        },
        matches(FLOAT_RX),
      ],
      [::Float,
        Proc.new{|t, v| Float(v) },
        Proc.new{|t, v|
          case v
          when Rational
            v.to_f
          when Numeric, String
            Float(v)
          when Time
            v.to_f
          end
        },
        matches(FLOAT_RX),
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
          when String
            Time.parse(t.match(v))
          end
        },
        matches(/^(\d\d\d\d-\d\d-\d\d[-T ]\d\d:\d\d:\d\d(\.\d+)?(-\d\d:\d\d|Z)?)$/i),
        Proc.new {|t, v| v.iso8601(6)}
      ],
      [::Date,
        Proc.new {|t, v| Date.parse(t.match(v))},
        Proc.new {|t, v|
          case v
          when Time
            v.to_date
          when Numeric          
            Time.at(v.to_f).to_date
          when String
            Date.parse(t.match(v))
          end
        },
        matches(/^(\d\d\d\d-(0\d|10|11|12)-([012]\d|30|31))$/),
      ],
      [::Boolean,
        Proc.new do | v |
          case v
          when "true"
            true
          when "false"
            false
          end
        end,
        Proc.new{|t, v|
          case v
          when Numeric
            ! v.zero?
          when String
            case v
            when /^(true|t|-?[1-9]\d*)$/i
              true
            when /^(false|f|0+)$/i
              false
            end
          end
        },
        matches(/^(true|false)$/i),
      ],
      [::String,
        Proc.new{|t, v| v.to_s },
        Proc.new{|t, v| v.to_s },
        ANY,
      ],
      [::Symbol,
        Proc.new{|t, v| v.to_sym},
        Proc.new{|t, v|
          case v
          when String
            v.to_sym
          end
        },
        NONE,
      ],
     [::Object,
       Proc.new{|t, v| v },
       Proc.new{|t, v| v },
       ANY,
       Proc.new{|t, v| v.inspect},
     ],
   ].each do | args |
     add!(*args)
   end
  end
end
