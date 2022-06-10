# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/io_buffer'
require 'builder' # XML https://github.com/jimweirich/builder
require 'cgi/util'

class CX::HtmlMarkup < ::Builder::XmlMarkup
  attr_accessor :indent_enabled, :attrs_enabled, :file_content_path

  def initialize *args
    super
    @indent_enabled = true
    @attrs_enabled = true
    @file_content = { }
    @file_content_path = '.'
  end

  def raw! s
    @target << s
    self
  end

  def text! s
    raw! escape(s)
  end

  def escape s
    ::CGI::escapeHTML(s.to_s)
  end

  def comment! s
    raw! "<!-- #{s} -->"
  end

  def css! content
    emit_content! :style, content, "text/css"
  end

  def js! content
    emit_content! :script, content, "text/javascript"
  end

  def html! content
    emit_content! :script, content, "text/html"
  end
  
  def emit_content! tag, content, type = nil
    if content
      msg = "cx : content : #{type || 'text/plain'} : #{content.file rescue 'UNKNOWN-FILE'}"
      raw! "\n"
      comment!("#{msg} : BEGIN")
      raw! "\n"
      case type
      when nil, 'text/html', 'text/plain'
        raw! content
      else
        __send__(tag, type: type) do
          raw! content
        end
      end
      raw! "\n"
      comment!("#{msg} : END")
      raw! "\n"
      self
    end
  end

  # Try NAME.min.EXT or NAME.EXT
  def file_content_min! name
    file_content!(name.sub(/.([^.]+)$/, '.min.\1')) || file_content!(name)
  end
  
  def file_content! name
    @file_content[name] ||= _read_content!(name) 
  end

  def _read_content! name
    if str = (::File.read("#{@file_content_path}/#{name}") rescue nil)
      def str.file val = nil
        @from_file = val unless val.nil?
        @from_file
      end
      str.file(name)
    end
    str
  end

  def indent! state = true
    save = @indent_enabled
    begin
      @indent_enabled = state
      yield
    ensure
      @indent_enabled = save
    end
  end

  def _indent
    super if @indent_enabled
  end
  def _newline
    super if @indent_enabled
  end
  def _insert_attributes(attrs, order=nil)
    super(attrs, order || []) if @attrs_enabled
  end
end

