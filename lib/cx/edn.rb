# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/structured'
# require 'edn'

module CX
  class EdnOut < StructuredOut
  # TODO: use a supported EDN library?
  def sep ; "" ; end
  def line row, row_delim
    case row
    when Hash
      clj_map(row, row_delim)
    else
      clj_vec(row, row_delim)
    end
  end

  def clj_map row, row_delim
    (row_delim[0] || '{') +
    row.map do| (k, v) |
      key_xform(k) + ' ' << val_xform(v)
    end * ' ' +
    + (row_delim[1] || '}')
  end

  def clj_vec row, row_delim
    (row_delim[0] || '[') +
    row.map{|v| val_xform(v)} * ' '
    + (row_delim[1] || ']')
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
    when Symbol then ":#{v}"
    when String then v.inspect # kinda close?
    when nil    then "nil"
    when Hash       then clj_map(v, @map_delim ||= ['{', '}'])
    when Enumerable then clj_vec(v, @vec_delim ||= ['[', ']'])
    else             v.to_s
    end
  end
end
end
