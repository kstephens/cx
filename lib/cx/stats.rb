# frozen_string_literal: true

require "cx"
require "cx/struct"
require "bigdecimal"
require "rational"

class ::Rational
  def inspect
    "Rational(#{numerator},#{denominator})"
  end
end

module CX
  class Stats < Struct.new(
    :id,
    :values, :nils,
    :count, :sum, 
    :min, :max, :range, :width,
    :mean, :stddev,
    :mid, :median,
    :n_bins, :bins_range, :bins,
    :val_to_idx, :idx_to_val,
    :value_types, :value_type,
    :ratio_fn,
  )
    include StructSupport

    def initialize(*args)
      super
      self.values ||= []
      self.nils = 0
    end

    def <<(v)
      case v
      when Numeric
        values << v
      when nil
        self.nils += 1
      else
        raise TypeError, "not numeric or nil: #{v.inspect}"
      end
      self
    end

    def ratio(a, b)
      ratio_fn.call(a, b)
    end

    def complete!
      prepare_values!
      basic!
      return self if count.zero?
      ratio!
      mean!
      bins! if n_bins
      median!
      collapse_bins! if n_bins
      # binding.pry if count == 2
      self
    end

    def prepare_values!
      self.nils += values.count(nil)
      values.compact!
      values.sort!
      self.value_types = Set.new(values.map(&:class)).to_a.sort_by!(&:name)
      self.value_type = value_types.first if value_types.size == 1
      self
    end

    def ratio!
      self.ratio_fn ||=
        case value_types
        when [::Integer], [::Rational], [::Integer, ::Rational]
          Proc.new { |a, b| Rational(a, b) }
        when [::BigDecimal], [::BigDecimal, ::Integer]
          Proc.new { |a, b| BigDecimal(a) / BigDecimal(b) }
        else
          Proc.new { |a, b| a.to_f / b.to_f }
        end
      self
    end
    
    def basic!
      self.count = values.size
      return nil if count.zero?
      self.min, self.max = values[0], values[-1]
      self.width = max - min
      self.range = count.zero? ? nil : min..max
      self.sum = count == 1 ? min * count : values.sum
      self
    end

    def mean!
      self.mean = count == 1 ? min : ratio(sum, count)
      self.stddev = self.count < 2 ?
        nil :
        Math.sqrt(ratio(values.sum { |v| (v - mean) ** 2 }, count))
      self
    end

    def bins!
      self.bins = (1 .. n_bins).map { |_| [] }
      self.bins_range ||= min .. max
      bin_width = bins_range.max - bins_range.min
      @bin_scale = bin_width.zero? ? 1 : ratio(n_bins, bin_width)
      
      self.val_to_idx = lambda do |v|
        if bins_range.include?(v)
          i = ((v - bins_range.min) * @bin_scale).to_i
          i =- 1 if v == bins_range.max
          i
        else
          nil
        end
      end
      
      self.idx_to_val = lambda do |i|
        bins_range.min + i / @bin_scale
      end
      
      values.each do |v|
        if idx = val_to_idx[v]
          raise if bins[idx].nil?
          bins[idx] << v
        end
      end
      self
    end

    def median!
      case
      when count.zero?
      when count.odd?
        self.mid     = count / 2
        self.median  = values[mid]
      else
        self.mid     = count / 2 - 1
        self.median  = ratio(values[mid] + values[mid + 1], 2)
      end
      self
    end

    def collapse_bins!
      self.bins = bins.map!.with_index do |vals, i|
        [idx_to_val[i]...idx_to_val[i + 1], vals.tally]
      end
      if count > 1
        bin_l = bins.first
        bin_l[0] = bins_range.min   ... bin_l[0].end
        bin_r = bins.last
        bin_r[0] = bin_r[0].begin   ..  bins_range.max
      end
      self
    end
  end
end
