# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/boolean'
require 'cx/type'
require 'cx/typed_accessor'

module CX
  class Meta
    include Support
    extend CX::TypedAccessor
    
    ATTRS =
      [
        [:name,       type: Symbol, delegate: false],
        [:name_,      type: Symbol, delegate: false],
        [:visible,    type: Boolean],
        [:order,      type: Integer, delegate: false],
        [:index,      type: Integer, delegate: false],
        [:type,       type: Module],
        [:min_size,   type: Integer],
        [:max_size,   type: Integer],
        [:min_value,  type: Object],
        [:max_value,  type: Object],
        [:blanks,     type: Integer],
        [:nulls,      type: Integer],
        [:format,     type: String],
        [:align,          type: Symbol],
        [:align_inferred, type: Symbol],
        [:types,          type: Set], # Set.new([Module])
        [:type_inferred,  type: Module],
        # [:version,        type: Integer, delegate: true],
      ]
    attr_accessor_typed *ATTRS

    #####################################

    eval(ATTRS.map{|(name, opts)| opts[:delegate] ? name : nil}.compact.map do | name |
<<"END"
def #{name}     ; raise unless @owner; @owner.#{name}      rescue nil ; end
def #{name}= x  ; raise unless @owner; @owner.#{name} = x  rescue nil ; end
END
    end * "\n")

    #####################################
    
    module Owner
      attr_reader :meta
      def meta= m
        if @meta = m
          @meta.owner = self
        end
      end
    end

    #####################################
    
    attr_reader :state, :opts
    attr_accessor :owner
    
    def initialize owner = nil
      raise unless owner
      @owner = owner
      self.visible = true
      @opts = { }
      clear!
    end

    def initialize_copy orig
      super
      @types = @types.dup
      @state = nil
    end

    def inspect_content mode
      to_h.inspect
    end

    def column! c
      # ??? delegate to @owner?
      @name  = c.name
      @name_ = c.name_
      @index = c.index
      @order = c.order
      # @version = c.version
      self
    end

    def header! h
      # ??? delegate to @owner?
      #@version = h.version
      self
    end

    def update_column! c
      # ??? delegate to @owner?
      c.name = @name
      c.order = @order
      column! c
    end
    
    def clear! c = nil
      column!(c) if c
      @types = Set.new
      @type_inferred = @align_inferred = nil
      @type_object = nil
      @min_width = @max_width = @min_value = @max_value = nil
      @blanks = @nulls = @whitespace = 0
      self
    end

    def clear_all!
      clear!
      @type = nil
    end

    ####################################################
    # Processing Lifecycle
    #

    def begin!
      case @state
      when nil, :inactive
        clear!
        @state = :active
      else
        check_state! :begin!
      end
      self
    end

    def end!
      check_state! :end!, :active
      @state = :inactive
      complete!
      self
    end
    
    def update! v
      check_state! :update!, :active
      case v
      when nil
        @nulls += 1
      when ''
        update_min_max_value! v
        @blanks += 1
      else
        v = update_min_max_value! v
        @whitespace += 1 if /\s/.match?(v)
      end
      v
    end

    def update_min_max_value! v
      min_max_value! v
      @types << v.class
      v = v.to_s # ??? use formatter?
      min_max_size! v.size
      v
    end

    def check_state! meth, expected = :UNEXPECTED
      unless @state == expected
        raise_ "#{meth} : invalid state : #{@state.inspect} : expected #{expected.inspect}"
      end
      self
    end

    ####################################################
    ## Update statisitics
    ##
    
    def min_max_size! val
      raise unless val
      check_state! :type!, :active
      @min_size = val if ! @min_size || @min_size > val
      @max_size = val if ! @max_size || @max_size < val
      self
    end

    def min_max_value! val
      return nil if val.nil?
      check_state! :type!, :active
      @min_value = val if ! @min_value || @min_value > val
      @max_value = val if ! @max_value || @max_value < val
      self
    rescue
      nil
    end

    def type! type
      check_state! :type!, :active
      @types << type
      self
    end

    def complete!
      check_state! :complete!, :inactive
      types.delete(NilClass)
      self.type_inferred = infer_type(types) unless types.empty?
      self.types = types.to_a.sort_by{|c| c.name}
      self.align_inferred = :right if numeric?
      self
    end

    def numeric? type = type_inferred
      type && type <= ::Numeric
    end
    
    def update_from_hash! h
      h.to_h.each do | k, v |
        send(:"#{k}=", (v.dup rescue v))
      end
      self
    end

    def align_
      align || align_inferred
    end

    def to_h
      ATTRS.map(&:first).map{|k| [k, send(k)]}.to_h.merge(@opts)
    end

    def table
      header = Header.new
      ATTRS.each do | (name, opts) |
        type = opts[:type_inferred] || opts[:type]
        type = type.first if Array === type
        
        opts[:align_inferred] ||= align_for_type(type)
        
        type = opts[:type_inferred] || opts[:type]
        type = type.first if Array === type

        opts[:align] ||= align_for_type(type)
        
        col = Column.new(name)
        col.meta.update_from_hash!(opts.merge(name: name, type: type))
        header << col
      end
      
      header[:min_value].meta.type =
        header[:max_value].meta.type =
        type
      
      table_add_opts_columns!(Table.new([], header))
    end

    def table_add_opts_columns! table
      header = table.header
      @opts.each do | name, val |
        unless header[name]
          col = Column.new(name)
          col.meta.update_from_hash!(name: name, type: String)
          header << col
        end
      end
      table
    end
    
    def align_for_type type
      numeric?(type) ? :right : nil
    end

    def type_
      @type  || @type_inferred
    end
    
    def align_
      @align || @align_inferred || align_for_type(type_)
    end

    def type= x
      self.__type = x
      @type_object = nil
    end
    
    def type_inferred= x
      self.__type_inferred = x
      @type_object = nil
    end
    
    def type_object
      @type_object ||= Type[type_] unless type_.nil?
    end

    def infer_type types
      ts = types.to_a
      t1 = ts.shift
      t1 = ts.inject(t1){|t1, t2| type_lcm(t1, t2)}
      # pp(infer_types: types, result: t1) if debug?
      t1
    end

    def type_lcm t1, t2, ignore = nil
      TYPE_LCM[[t1, t2, ignore]] ||=
        begin
          _ignore = (ignore || []) + IGNORE
          ((t1.ancestors - _ignore) & (t2.ancestors - _ignore))
            .reject{|m| m.class == Module}
            .sort
            .first
        end
    end

    def method_missing sel, *args, &blk
      sel_s = nil
      case
      when ! blk && args.size == 1 && (sel_s ||= sel.to_s) =~ /^(\w+)=$/
        @opts[$1.to_sym] = args.first
      when ! blk && args.size == 0 && (sel_s ||= sel.to_s) =~ /^\w+$/
        @opts[sel]
      else
        super(sel, *args, &blk)
      end
    end
    
    TYPE_LCM = { }
    EMPTY_Array = [].freeze
    IGNORE = [ NilClass ]
  end
end

