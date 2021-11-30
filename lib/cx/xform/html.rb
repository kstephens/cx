# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/io_buffer'
require 'builder' # XML https://github.com/jimweirich/builder

# :COMMAND:
# HtmlOut:
#   aliases: html,htm
#   synopsis: 'Emits HTML.'
#   args: []
#   opts:
#     raw:        'Comma-separated list of columns that contain raw HTML.'
#     filtering:  'Adds a filtering input box.'
#     title:      'Sets the <title>.'
#     table-only: 'Emit the <table> without <html>, <head>, <body>.'
#     indent:     'Spaces to indent.  Default: 1'
#     filtering:  'Enable filtering.  Default: true'
#     sorting:    'Enable sorting.  Default: true'
#     styled:     'Enable styling.  Default: true'
#     head:       'Additional raw HTML at foot of <head>.'
#     body-head:  'Additional raw HTML at head of <body>.'
#     body-foot:  'Additional raw HTML at foot of <body>.'

module CX
  module Xform
    class HTMLOut
      include OutputFormat, RecordOut
      def initialize!
        super
        @raw_columns = Set.new((opts[:raw] || '')
          .strip.split(/\s*,\s*/, -1)
          .map(&:to_sym)
          .uniq)
        self
        @indent      = opts.fetch(:indent, 1).to_i
        @coerce      = opts[:coerce_to_string] || proc{|x| x}
        @table_only  = opts.fetch(:table_only, false)
        @filtering   = opts.fetch(:filtering, true)
        @filtering   = false if @table_only
        @sorting     = opts.fetch(:sorting, true)
        @sorting     = false if @table_only
        @styled      = opts.fetch(:styled, true)
      end

      def call input, env
        @resource = env[:html] ||= {resource: { }}
        @once = (@resource[:once] ||= {})
        output = make_output
        this = self
        out = IOBuffer.new(lambda{|line| output << [ line ]})
        call_(input, env, out)
        output
      end

      attr_reader :h, :colspan, :cols, :col_data, :header, :right
      
      def call_ input, env, out
        @header = input.header
        @cols = header.ordered
        @colspan = 1 + cols.size
        @right = {style: 'text-align: right;'}
        # @h = XMLWriter.new(out, indent: opts[:indent])
        @h = HtmlMarkup.new(target: out, indent: @indent)
        @h.attrs_enabled = @styled || @sorting || @filtering
        @col_data = Hash.new{|h, k| h[k] = {}}

        cols.each do | c |
          data = col_data[c]
          data[:style] = right[:style] if c.meta.align_ == :right
        end

        if @table_only
          html_table(input, env)
        else
          html_body(input, env) do
            html_table(input, env)
          end
        end
        
        @header = @cols = @h = @col_data = nil
        env[:content_type] = 'text/html'
        nil
      end

      def raw! x
        h.raw! x.to_s
      end
      def text! x
        raw! @coerce.call(x).to_s
      end

      def html_body input, env
        h.raw! "<!DOCTYPE html>\n"
        h.html do
          h.head do
            x = opts[:title] || env[:in_file] and h.title(x)
            if @styled
              css read_content('cx.css')
            end
            h.raw! read_content('header.html')
            x = opts[:head] and h.raw!(x)
          end
          h.body do
            x = opts[:body_head] and h.html(x)
            h.div(id: 'cx-content', class: 'cx-content') do
              x = opts[:title] and h.div({id: 'cx-title', class: 'cx-title'}, x)
              yield
            end
            x = opts[:body_foot] and raw!(x)
          end
          if @filtering
            js read_content_once("filter.js")
          end
          if @sorting
            js read_content_once("tablesort.js")
            js "new Tablesort(document.getElementById('cx-table'));"
          end
          raw! read_content('footer.html')
        end
      end
      
      def html_table input, env
        h.table(id: 'cx-table', class: 'cx-table') do
          html_header(input, env) if include_header?
          h.tbody({id: "cx-tbody"}) do
            ri = 0
            input.each do | r |
              ri += 1
              row_tooltip = "#{ri}/#{input.size}"
              # row_tooltipe << ": #{r[inds[0]]}" # TODO: make this optional
              h.tr(title: row_tooltip) do
                h.td(right, ri)
                cols.each do | c |
                  data = col_data[c]
                  h.indent!(false) do
                    h.td(title: "#{row_tooltip} - #{c.name}", style:  data[:style]) do
                      if @raw_columns.include?(c.name)
                        raw!(r[c])
                      else
                        text!(render(r[c]))
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end

      def html_header input, env
        h.thead(id: 'cx-thead', class: 'cx-thead') do
          html_filtering(input, env) if opts[:filtering]
          h.tr(class: 'cx-columns') do
            a_base = {class: 'cx-column'}
            a_row_number = a_base
            if @sorting
              a_row_number = a_row_number.merge("data-sort-method" => :number)
            end
            h.th(a_row_number, "#")
            cols.each do | c |
              a = a_base
              if @filtering
                a = a.merge("data-filter-name" => c.name_)
              end
              if @sorting
                a = a.merge("data-sort-method" => :number) if c.meta.align_ == :right
              end
              a = a.merge(title: "type: #{c.meta.type_ || :UNKNOWN}")
              h.th(a, c)
            end
          end
        end
      end

      def html_filtering input, env
        h.tr(id: 'cx-filter', class: 'cx-filter') do
          h.th(class: 'cx-filter', colspan: colspan) do
            h.span(class: 'cx-filter') do
              h.input({type: "text",
                id: 'cx-filter-input',
                class: "cx-filter-input",
                onkeyup: "cx_filter_rows()",
                placeholder: "#{UNICODE[:search]} Filter..."})
            end
            h.span(class: 'cx-row-count-span') do
              h.span({id: 'cx-matched-row-count'}, input.size.to_s)
              h.text!('/')
              h.span({id: 'cx-row-count'}, input.size.to_s)
            end
          end
        end
      end
      
      def html_sorting input
      end
      
      def render x
        case x
        when Hash
          x.map do |k,v|
            render(k) + "=" + render(v)
          end * ';'
        when Enumerable
          x.map{|x| render(x)} * ';'
        # when Symbol
        # x.inspect
        else
          x.to_s
        end
      end
      
      def css content
        if content
          h.style(type: "text/css") do
            raw! content
          end
        end
      end

      def js content
        if content
          h.script(type: "text/javascript") do
            h.raw! content
          end
        end
      end
      
      def read_content name
        File.read(File.expand_path("../html/#{name}", __FILE__))
      end

      def read_content_once name
        unless @once[name]
          @once[name] = true
          read_content(name)
        end
      end
      
     UNICODE = {
       # Left-Pointing Magnifying Glass : U+1F50D
       search: "🔍",
     }
    end
  end
end

require 'cgi/util'
module CX
  class HtmlMarkup < Builder::XmlMarkup
    attr_accessor :indent_enabled, :attrs_enabled
    def initialize *args
      super
      @indent_enabled = true
      @attrs_enabled = true
    end
    
    def raw! s
      @target << s
    end
    def text! s
      raw! ::CGI::escapeHTML(s.to_s)
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
      if @attrs_enabled
        super(attrs, order || [])
      end
    end
  end
end
