# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/structured'

module CX
  class TextOut < StructuredOut
    def content_type ; 'text/plain' ; end
    def init_more!
      super
      opts[:field_sep] ||= " "
      opts[:row_sep]   ||= "\n"
    end

    # def newline; '' ;end

    def line row
      case row
      when Hash
        text_map(row, row_delim)
      else
        # pp(row: row)
        text_vec(row, row_delim)
      end
    end

    def text_map row, delim
      row.map do| (k, v) |
        k = if k = key_xform(k)
          k + ' '
        else
          ''.dup
        end
        k << val_xform(v)
      end * field_sep
    end

    def text_vec row, delim
      row.map{|v| val_xform(v)} * field_sep
    end
    
    def field_sep
      @field_sep ||= opts[:field_sep]
    end
    def seq_delim
      @seq_delim ||= [ '', '' ]
    end
    def row_delim
      @row_delim ||= [ '', opts[:row_sep] ]
    end
    def newline
      ''
    end
    
    def key_xform k
      case k
      when String, Symbol
        @styles ||= (opts[:key_style] || 'keyword').split(/,/, -1)
        @styles_sel ||= @styles.map {|style| :"key_#{style}!" }
        @styles_sel.inject(k.to_s) {|k, style| send(style, k) }
      else
        val_xform k
      end
    end
    def key_none! k
      nil
    end
    def key_keyword! k
      ":#{k.gsub(/\s+/, '-')}"
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

    def quote?
      opts[:quote]
    end
    
    def val_xform v
      case v
      when Symbol     then quote? ? ":#{v}" : v.to_s
      when String     then quote? ? v.inspect : v.to_s
      when nil        then quote? ? "nil" : ""
      when Hash       then text_map(v, @map_delim ||= ['{', '}'])
      when Enumerable then text_vec(v, @vec_delim ||= ['[', ']'])
      else            v.to_s
      end
    end
  end
end
