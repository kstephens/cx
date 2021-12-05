# frozen_string_literal: true

require 'cx'

module CX
  class Row
    include Enumerable

    attr_reader :header, :data, :header_version
    attr_accessor :file_name, :line_number

    def inspect_content mode
      to_h.inspect
    end

    def self.[] x
      case x
      when self, nil
        x
      else
        new(x)
      end
    end

    def initialize data = nil, header = nil
      set_data! data
      @header = header
    end

    def initialize_copy orig
      super
      set_data! @data.dup
      @meta = @meta && @meta.dup
    end

    def set_data! data
      raise_ "data already set to #{@data.class}" if @data && @data.class != data.class
      case @data = data
      when Array
        extend ArrayRow
      when Hash
        extend HashRow
      else
        raise_ "unexpected data #{@data.class}"
      end
    end
    
    def _header= h
      @header = h
      self
    end

    def each cols = nil
      (cols || @header).each do |c|
        yield(c, _get(c))
      end
      self
    end
    
    def map! cols = nil
      (cols || @header).each do |c|
        _set(c, yield(c, _get(c)))
      end
      self
    end

    def size  ; @header.size        ; end
    def first ; _get(@header.first) ; end
    def last  ; _get(@header.last)  ; end

    def map_columns!
      @header.columns.each{|c| r[c] = yield c, r[c]}
      self
    end
    
    ###########################

    def [] k
      case k
      when Column
        _get(k)
      when Symbol, String, Integer
        _get(@header[k])
      when nil
        nil
      else
        raise_ TypeError, "[] : unexpected #{k.inspect}"
      end
    end

    def []= k, v
      case k
      when Column
        _set(k, v)
      when Symbol, String, Integer
        _set(@header[k], v)
      when nil
        nil
      else
        raise_ TypeError, "[]= : unexpected #{k.inspect}"
      end
    end

    def vals x
      x.map{|k| _get(k)}
    end

    def keys
      @header
    end

    def values
      vals @header
    end
    alias :to_a :values

    def first ; _get(@header.first) ; end
    def last  ; _get(@header.last)  ; end

    def to_h cols = @header
      h = { }
      cols.each do | c |
        h[c.to_sym] = _get(c)
      end
      h
    end

    def write out = nil
      out ||= $stdout
      each{|v| out.write(v.to_s)}
      nil
    end

    ###########################

    module ArrayRow
      def _get k
        @data[k.to_i]
      end
      def _set k, v
        @data[k.to_i] = v
      end
    end
    
    module HashRow
      def _get k
        @data[k.to_sym]
      end
      def _set k, v
        @data[k.to_sym] = v
      end
    end
  end
end

