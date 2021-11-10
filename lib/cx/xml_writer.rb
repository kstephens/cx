# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cgi/util'

module CX
  # Could probably reuse some library, this was not hard to write.
  class XMLWriter < Object # BasicObject
    def initialize out, opts = { }
      @out = out
      @opts = opts.dup
      @coerce = opts[:coerce_to_string] || proc{|x| x}
    end
    @@tag_sep   = ::Hash[%w(span td th title meta).map{|t| [t.to_sym, ""]}]
    @@tag_open  = ::Hash.new{|h, tag| h[tag.to_sym] = "<#{tag}>".freeze}
    @@tag_close = ::Hash.new{|h, tag| h[tag.to_sym] = "</#{tag}>".freeze}
    
    def _tag tag, attrs = nil, content = nil, &blk
      tag = tag.to_sym
      case
      when ::Hash === attrs
        attrs = attrs.map{|k,v| v.nil? || "#{k}='#{v}'"}.compact
        attrs = attrs.empty? ? nil : attrs.join(' ')
      when ::String === attrs && ! content
        content = attrs
        attrs = nil
      end
      ws = @@tag_sep[tag] ||= "\n"

      self << (attrs ? "<#{tag} #{attrs}>" : @@tag_open[tag]) << ws

      case
      when content
        close = true
        text(content)
      when blk
        close = true
        yield self
      else
        close = false
      end
      
      self << @@tag_close[tag] << "\n" if close
      nil
    end
    
    def raw! x ; @out.write x.to_s ; self ; end
    alias :<< :raw!
    def text x
      raw! ::CGI::escapeHTML(@coerce.call(x))
    end

    def method_missing sel, *args, &blk
      _tag(sel, *args, &blk)
    end
  end
end
