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
      @out, @opts = out, opts
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

      # parent_tag = @tag_stack[-1]
      self << (attrs ? "<#{tag} #{attrs}>" : @tag_open[tag])
      @tag_stack.push tag
      @level += 1
      indent_sep = indent_sep(@open_indent[@last_tag] || "\n")
      self << indent_sep

      close_tag =
      case
      when content
        text(content)
        true
      when blk
        yield self
        true
      end

      @level -= 1
      if close_tag
        indent_sep = indent_sep(@open_indent[@last_tag] || "\n")
        self << indent_sep
        self << @tag_close[tag]
      end
      @last_tag = tag
      nil
    end
    
    def raw! x ; @out.write x.to_s ; self ; end
    def << x   ; raw! x            ; self ; end

    def indent_sep sep
      if @indent
        sep.sub(/\n/m) do |m|
          "\n" + (@indent_cache[@level] ||= @indent * @level)
        end
        # pp(level: @level, sep: sep)
      else
        sep
      end
    end
    
    def text x
      raw! ::CGI::escapeHTML(@coerce.call(x).to_s)
    end

    def css content
      if content
        self.style(type: "text/css") do
          raw! content
        end
      end
    end

    def js content
      if content
        script(type: "text/javascript") do
          raw! content
        end
      end
    end

    def method_missing sel, *args, &blk
      _tag(sel, *args, &blk)
    end
    
  end
end
