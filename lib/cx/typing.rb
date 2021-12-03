# frozen_string_literal: true

require 'cx'
require 'cx/table'
require 'rational'
require 'bigdecimal'

module CX
module Typing
  extend Logging

  module Boolean ; end

  def self.col_type v
    case v
    when nil # inconclusive
      nil
    when String
      # May be inconclusive
      # Remove currency symbols
      v = v.strip.gsub(/[§¤£$Û¢´€]/, '').downcase
      case 
      when v == ''
      # inconclusive
      when BOOLEANS.include?(v)
        Boolean
      when (Integer(v) rescue nil)
        Integer
      when (BigDecimal(v) rescue nil)
        # Prefer BigDecimal over Float... it is more likely to roundtrip.
        BigDecimal
      when (Float(v) rescue nil)
        Float
    # when (Rational(v) rescue nil)
        # Rational("123/345").to_s == "41/115"
        # This could be very confusing when roundtripping:
    #   Rational
      else
        String
      end
    when Numeric
      Numeric
    when TrueClass, FalseClass
      Boolean
    else
      v.class
    end
  end
  BOOLEANS = [ 'true', 'false' ].freeze

  def self.type_ge t1, t2
    unless x = TYPE_GE[t1][t2]
      ge = type_ge_(t1, t2)
      pp(t1: t1, t2: t2, ge: ge) if debug?
      x = TYPE_GE[t1][t2] = [ ge ]
    end
    x[0]
  end
  TYPE_GE = Hash.new{|h1, k1| h1[k1] = {}}

  def self.type_ge_ t1, t2
    case
    when t1 == nil
      false
    when t2 == nil
      true
    when t1 <= Symbol
      true
    when t1 <= String
      true
    when t1 <= Numeric && ! (t2 <= Numeric)
      false
    when t1 <= BigDecimal
      # Prefer BigDecimal over Float... it is more likely to roundtrip.
      true
    when t1 <= Float
      true
    when t1 <= Rational
      case
      when t2 <= Integer
        true
      when t2 <= Float
        false
      else
        true
      end
    when [Boolean, TrueClass, FalseClass].include?(t1)
      case
      when [Boolean, TrueClass, FalseClass, NilClass, nil].include?(t2)
        true
      else
        false
      end
    else
      t1 == t2
    end
  end

  def self.coerce x, type
    type_coercer(type).call(x)
  end

  def self.type_coercer type
    TYPE_COERCER[type] ||= TYPE_COERCER[nil]
  end

  TYPE_COERCER = {
    BigDecimal  => Proc.new do |x|
      x.nil? || (x = x.to_s).empty? ? 0 : BigDecimal(x)
    end,
    Float    => Proc.new{|x| x.to_f},
    Rational => Proc.new{|x| x.to_r},
    Integer  => Proc.new{|x| x.to_i},
    Symbol   => Proc.new{|x| x.to_s.to_sym},
    Boolean  => Proc.new{|x| x =~ /t/i ? true : false},
    String   => Proc.new{|x|
      case x
      when Float, BigDecimal
        "%g" % x
      else
        x.to_s
      end
    },
    nil      => Proc.new{|x| x},
  }
  TYPE_COERCER[TrueClass] = TYPE_COERCER[FalseClass] = TYPE_COERCER[Boolean]

  NAME_TO_TYPE =
    Hash[TYPE_COERCER.keys.map{|cls| [cls && cls.name.sub(/.*::/, ''), cls]}]
  ['TrueClass', 'FalseClass'].map{|s| NAME_TO_TYPE.delete(s)}
  TYPE_TO_NAME =
    Hash[NAME_TO_TYPE.map(&:reverse)]
  NAME_TO_TYPE.values.each{|cls| NAME_TO_TYPE[cls] = cls }
  NAME_TO_TYPE["Numeric"] = ::Numeric
  
  def self.compare type, a, b
    case
    when a.class == b.class
      a <=> b
    when a.nil? && b.nil?
      0
    when a.nil?
      -1
    when b.nil?
      1
    when ! type
      a.to_s <=> b.to_s
    else
      coerce(a, type) <=> coerce(b, type)
    end
  end

  def self.first_superclass classes, cls
    classes
      .each_with_index
      .map do |o,i|
      [cls <= o, o, i]
    end
      .select(&:first)
      .each(&:shift)
      .first
  end

  module Column
    def type         ; opts[:type]      || @type            ; end
    def type= x      ; opts[:type]       = NAME_TO_TYPE[x] ; default_justify! ; end
    def min_width    ; opts[:min_width] || @min_width       ; end
    def min_width= x ; opts[:min_width]  = x.to_i           ; end
    def max_width    ; opts[:max_width] || @max_width       ; end
    def max_width= x ; opts[:max_width]  = x.to_i           ; end
    def justify      ; opts[:justify]   || @justify         ; end
    def justify= x   ; opts[:justify]    = x && x.to_sym    ; end
    attr_reader :n_values, :n_blanks, :n_nulls, :min, :max

    def col_type! v
      col_width! v
      col_min_max! v
      v_type = Typing.col_type(v)
      new_type = Typing.type_ge(v_type, @type) ? v_type : @type
      if debug?
        pp(col_type!: self,
           v: v, v_cls: v.class, v_type: v_type,
           c_type:    type)
        puts
      end
      @type = new_type
      self
    end
    
    def clear_type!
      @type = @min_width = @max_width = @n_values = @n_blanks = @n_nulls = @min = @max = nil
      self
    end
    def default_type!
      @type ||= ::String
      default_justify!
    end
    def default_justify!
      @n_values ||= 0
      @n_blanks ||= 0
      @n_nulls  ||= 0
      @justify = type && type <= Numeric ? :right : nil
      self
    end

    def clear_min_max!
      @min = @max = nil
      self
    end

    def col_min_max! v
      unless v.nil?
        @min = v if @min.nil? || @min > v 
        @max = v if @max.nil? || @max < v
      end
      self
    rescue
      self
    end

    def col_width! v
      @n_values ||= 0; @n_values += 1
      if v.nil?
        @n_nulls ||= 0; @n_nulls += 1
      end
      str = Typing.coerce(v, String)
      if str.empty?
        @n_blanks ||= 0; @n_blanks += 1
      end
      width = str.size
      @min_width = width if (@min_width ||= 99999) > width  
      @max_width = width if (@max_width ||=    -1) < width  
      self
    end

    def coerce v
      Typing.type_coercer(type).call(v)
    end
  end

  module Header
    def col_types? ; @col_types_ready; end
    def col_types! row, cols = self.cols
      @col_types_ready = false
      puts "\ncol_types! #{row.inspect}" if debug?
      cols.each do | c |
        c.col_type! row[c.to_i]
      end
      puts "col_types! #{map(&:type).inspect}\n" if debug?
      self
    end
  
    def clear_types!
      @col_types_ready = false
      each{|c| c.clear_type!}
      self
    end
  
    def finalize_types!
      unless @col_types_ready
        each{|c| c.default_type!}
        @col_types_ready = true
      end
      self
    end
  end
end

class Header
  include Typing::Header
  class Column
    include Typing::Column
  end
end

end
