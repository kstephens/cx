# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'builder' # XML https://github.com/jimweirich/builder
require 'cx/io_buffer'

module CX
  module Xform
    class HTMLOut
      include LineOut, Xform
      # :COMMAND:
      # HtmlOut:
      #   name: html-
      #   aliases: html
      #   synopsis: Emits HTML.
      #   args: []
      #   opts:
      #     raw:        Columns that contain raw HTML.
      #     filtering:  Adds a filtering input box.
      #     title:      Sets the <title>.
      #     head:       Additional raw HTML at foot of <head>.
      #     body-head:  Additional raw HTML at head of <body>.
      #     body-foot:  Additional raw HTML at foot of <body>.
      def initialize!
        super
        @raw_columns = Set.new((opts[:raw] || '')
          .strip.split(/\s*,\s*/, -1)
          .map(&:to_sym)
          .uniq)
        self
        opts[:filtering] = true; # ???
        opts[:indent] = 2
        @coerce = opts[:coerce_to_string] || proc{|x| x}
      end

      def call input, env
        @resource = env[:html] ||= {resource: { }}
        @once = (@resource[:once] ||= {})
        this = self
        out = IOBuffer.new(lambda{|line| this << line})
        call_(input, env, out)
        output
      end

      attr_reader :h
      
      def call_ input, env, out
        header = input.header
        cols = header.columns
        colspan = 1 + cols.size
        right = {style: 'text-align: right;'}
        # @h = XMLWriter.new(out, indent: opts[:indent])
        @h = HtmlMarkup.new(target: out, indent: opts[:indent])
        col_data = Hash.new{|h, k| h[k] = {}}

        cols.each do | c |
          data = col_data[c]
          data[:style] = "text-align: right;" if c.meta.align_ == :right
        end

        h.html do
          h.head do
            x = opts[:title] || env[:in_file] and h.title(x)
            css read_content('cx.css')
            h.raw! read_content('header.html')
            x = opts[:head] and h.raw!(x)
          end
          h.body do
            x = opts[:body_head] and h.html(x)
            h.div(id: 'cx-content', class: 'cx-content') do
              x = opts[:title] and h.div({id: 'cx-title', class: 'cx-title'}, x)
              h.table(id: 'cx-table', class: 'cx-table') do
                h.thead do
                  if opts[:filtering]
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
                  h.tr do
                    a = {class: 'cx-column-header'}
                    h.th(a.merge("data-sort-method" => :number), "#")
                    cols.each do | c |
                      a = a.merge("data-sort-method" => :number) if c.meta.align_ == :right
                      a = a.merge(title: "type: #{c.meta.type_ || :UNKNOWN}")
                      h.th(a, c)
                    end
                  end
                end
                size = input.size
                h.tbody({id: "cx-table-tbody"}) do
                  ri = 0
                  input.each do | r |
                    ri += 1
                    row_tooltip = "#{ri}/#{size}"
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
                              text!(r[c])
                            end
                          end
                        end
                      end
                    end
                  end
                end
              end
              x = opts[:body_foot] and raw!(x)
            end
          end
          js read_content_once("tablesort.js")
          js read_content_once("filter.js")
          js "new Tablesort(document.getElementById('cx-table'));"
          raw! read_content('footer.html')
        end
        @h = 0
        env[:content_type] = 'text/html'
        output
      end

      def raw! x
        h.raw! x.to_s
      end
      def text! x
        raw! @coerce.call(x).to_s
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
    def initialize *args
      super
      @indent_enabled = true
    end
    
    def raw! s
      @target << s
    end
    def text! s
      raw! ::CGI::escapeHTML(s.to_s)
    end
    
    def indent! state = true
      save = @indent_enabled
      @indent_enabled = state
      begin
        yield
      ensure
        @indent_enabled = save
      end
    end
    
    def _indent
      # binding.pry unless @indent_enabled
      super if @indent_enabled
    end
    def _newline
      super if @indent_enabled
    end
  end
end
