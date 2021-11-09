# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'date'
require 'time'
require 'bigdecimal'
require 'rational'
require 'set'

module Boolean
  ::TrueClass.include self
  ::FalseClass.include self
end  

module CX
  class Type < Struct.new(:mod, :converter, :coercer, :matches, :format, :name)
    def initialize *args
      super
      self.name = mod.name.to_sym
    end

    def convert v
      case v
      when mod, nil
        v
      else
        converter.call(self, v) rescue nil
      end
    end

    def coerce v
      case v
      when mod, nil
        v
      else
        if (vc = (converter.call(self, v) rescue nil)).nil?
          vc = matches.call(self, v)
          vc &&= converter.call(self, coercer.call(self, vc)) rescue nil
        end
        vc
      end
    end

    def parse v
      case v
      when mod, nil
        v
      when String
        if vp = matches.call(self, v)
          vp = converter.call(self, vp) rescue nil
        end
        vp
      else
        nil
      end
    end

    def self.try_parse! v
      return v if v.nil?
      return v unless String === v
      @@types.each do | t |
        # binding.pry if v.to_s =~ /%$/
        cv = t.parse(v)
        # pp(v: v, t: t.mod, cv: cv) if cv
        return cv unless cv.nil?
      end
      nil
    end

    @@types = [ ]
    @@types_by_module = { }
    @@types_by_name = { }

    def self.[] x
      case x
      when Module
        @@types_by_module[x]
      when Symbol, String
        @@types_by_name[x.to_sym]
      end or raise ArgumentError, "unknown Type #{x.inspect}"
    end

    def self.add! *args
      type = new(*args)
      @@types << type
      @@types_by_module[type.mod] = type
      @@types_by_name[type.name] = type
      self
    end

    ANY  = Proc.new {|t, v| v}
    NONE = Proc.new {|t, v| nil}
    def self.matches rx
      lambda do | t, v |
        String === v && rx.match(v) ? $1 : nil
      end
    end

    FLOAT_RX = /^([-+]?(\d+\.\d*|\.\d+|\d+)([efg][-+]?\d+)?)$/i
    [
      [::Integer,
        Proc.new{|t, v| Integer(v)},
        Proc.new{|t, v| v.to_i },
        matches(/^([-+]?\d+)$/),
      ],
      [::Rational,
        Proc.new{|t, v| Rational(v)},
        Proc.new{|t, v| v.to_r },
        matches(%r{^([-+]?\d+/\d+)$}),
      ],
      [::BigDecimal,
        Proc.new{|t, v| BigDecimal(v) },
        Proc.new{|t, v| v.to_s },
        matches(FLOAT_RX),
      ],
      [::Float,
        Proc.new{|t, v| Float(v) },
        Proc.new{|t, v| v.to_f },
        matches(FLOAT_RX),
      ],
      [::Time,
        Proc.new do |t, v|
          case v
          when Numeric          
            Time.at(v.to_f)
          else
            (format.parse(v) rescue nil) or
              (Time.parse(v) rescue nil)
          end
        end,
        Proc.new {|t, v| v.to_i },
        matches(/^(\d\d\d\d-\d\d-\d\d[-T ]\d\d:\d\d:\d\d(\.\d+)?)$/i),
      ],
      [::Date,
        Proc.new do |t, v|
          case v
          when Numeric          
            Time.at(v.to_f).to_date
          else
            (format.parse(v) rescue nil) or
              (Date.parse(v) rescue nil)
          end
        end,
        Proc.new{|t, v| v.to_s },
        matches(/^(\d\d\d\d-\d\d-\d\d)$/),
      ],
      [::Boolean,
        Proc.new do | v |
          case v
          when nil
            false
          when Numeric
            ! v.zero?
          when String
            v =~ /^[t1-9]/i ? true : false
          end
        end,
        Proc.new{|t, v| v.to_s },
        matches(/^(true|false)$/i),
      ],
      [::String,
        Proc.new{|t, v| v.to_s },
        Proc.new{|t, v| v.to_s },
        ANY,
      ],
      [::Symbol,
        Proc.new{|t, v| v.to_sym },
        Proc.new{|t, v| v.to_s },
        NONE,
     ],
     [::Object,
       Proc.new{|t, v| v },
       Proc.new{|t, v| v },
       ANY,
     ],
   ].each do | args |
     add!(*args)
   end
  end
end
