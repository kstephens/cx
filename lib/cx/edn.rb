# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/structured'
# require 'edn'

module CX
  class EdnOut < StructuredOut
    def content_type ; 'application/edn' ; end
    def init_more!
      super
      opts[:seq_delim] ||= '[]'
      if row_mode?
        opts[:row_delim] ||= '[]'
      else
        opts[:row_delim] ||= '{}'
      end
    end

    def line row
      case row
      when Hash
        clj_map(row, row_delim)
      else
        # pp(row: row)
        clj_vec(row, row_delim)
      end
    end

  def clj_map row, delim
    delim[0].to_s +
    row.map do| (k, v) |
      key_xform(k) + ' ' << val_xform(v)
    end * ' ' +
    delim[1].to_s
  end

  def clj_vec row, delim
    delim[0].to_s +
    row.map{|v| val_xform(v)} * ' ' +
    delim[1].to_s
  end
  
  def key_xform k
    case k
    when String, Symbol
      @styles ||= (opts[:key_style] || 'keyword').split(/,/, -1)
      @styles.inject(k.to_s){|k, style| send(:"key_#{style}!", k)}
    else
      val_xform k
    end
  end
  def key_keyword! k
    ":#{k}"
  end
  def key_uncamel! k
    k.gsub(/([a-z])([A-Z])/){|| $1 + '-' + $2}
  end
  def key_downcase! k
    k.downcase
  end
  def key_dash! k
    k.gsub(/[^-\w+]/, '-')
  end

  def val_xform v
    case v
    when Symbol     then ":#{v}"
    when String     then v.inspect # kinda close?
    when nil        then "nil"
    when Hash       then clj_map(v, @map_delim ||= ['{', '}'])
    when Enumerable then clj_vec(v, @vec_delim ||= ['[', ']'])
    else             v.to_s
    end
  end
end
end
