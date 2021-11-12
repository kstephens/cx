# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/format'

module CX
  class Formatter
    attr_reader :formats

    def initialize
      @format_for = { }
      @formats = [ ]
    end

    def [] x
      @format_for[x] or raise ArgumentError
    end

    def add! format
      @format_for[format.mod] = @format_for[format.name] = format
      @formats << format
      self
    end

    def parse v, fmt = nil
      @formats.each do | f |
        # ap(v: v, f: f)
        begin
          case v
          when f.mod
            return v
          else
            parsed = f.parse(v, fmt) and return parsed
          end
        rescue => e
          ap(e: e, backtrace: e.backtrace)
          nil
        end
      end
      nil
    end

    DEFAULT = Formatter.new
    [
      [::Integer,
        Proc.new {|v, fmt| Integer(v)}
      ],
      [::BigDecimal,
        Proc.new {|v, fmt| BigDecimal(v)},
      ],
      [::Rational,
        Proc.new do |v, fmt|
          ((v =~ %r{^[-+]?\d+/\d+} && Rational(v)) rescue nil) or
            (Float(v) rescue nil)
        end,
      ],
      [::Float,
        Proc.new {|v, fmt| Float(v)}
      ],
      [::Time,
        Proc.new do |v, fmt|
          case v
          when Numeric
            Time.at(v)
          else
            Time.parse(v)
          end
        end,
        Proc.new do |v, fmt|
          fmt ? v.strftime(fmt) : v.to_s
        end,
      ],
      [::Date,
        Proc.new do |v, fmt|
          (Date.parse(v) rescue nil) or
            Format[::Time].parse(v, fmt).to_date
        end,
        Proc.new do |v, fmt|
          fmt ? v.to_time.strftime(fmt) : v.to_s
        end,
      ],
      [::Symbol,
        Proc.new {|v, fmt| c.to_sym}
      ],
      [::String,
        Proc.new {|v, fmt| c.to_s}
      ],
    ].each do | args |
     Formatter::DEFAULT.add!(Format::new(*args))
   end
 end
  
end
