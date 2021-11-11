# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/xml_writer'
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
      end

      def call input, env
        out = IOBuffer.new(proc{|line| output << [ line ]})
        call_(input, env, out)
        output
      end
      
      def call_ input, env, out
        header = input.header
        cols = header.columns
        colspan = 1 + cols.size
        right = {style: 'text-align: right;'}
        h = XMLWriter.new(out)
        h.html do
         h.head do
           x = opts[:title] || env[:in_file] and h.title(x)
           h << read_content('header.html')
           x = opts[:head] and h.raw!(x)
         end
         h.body do
           x = opts[:body_head] and h.html(x)
           h.div(id: 'cx-content', class: 'cx-content') do
           x = opts[:title] and h.div({id: 'cx-title', class: 'cx-title'}, x)
           h.table(id: 'cx-table', class: 'cx-table') do
             h.thead do
               if opts[:filtering]
                 h.tr(class: 'cx-filter') do
                   h.span(class: 'cx-filter') do
                     h.th(class: 'cx-filter', colspan: colspan) do
                       h.input({type: "text",
                                id: 'cx-filter',
                                class: "cx-filter",
                                onkeyup: "cx_filter_rows()",
                                placeholder: "#{UNICODE[:search]} Filter..."})
                     end
                   end
                 end
               end
               h.tr do
                 a = {class: 'cx-column-header'}
                 h.th(a.merge("data-sort-method" => :number), "#")
                 cols.each do | c |
                   a = a.merge("data-sort-method" => :number) if c.meta.align == :right
                   h.th(a, c)
                 end
               end
             end
             size = input.size
             h.tbody({id: "cx-table-tbody"}) do
               td_attrs = cols.map{|c| c.meta.align == :right ? right : nil}
               raw_cols = cols.map{|c| @raw_columns.include?(c.name)}
               inds = cols.map(&:to_i)
               ri = 0
               input.each do | r |
                 ri += 1
                 row_tooltip = "Row #{ri} / #{size}"
                 # row_tooltipe << ": #{r[inds[0]]}" # TODO: make this optional
                 h.tr(title: row_tooltip) do
                   h.td(right, ri)
                   inds.each_with_index do | ci, i |
                     h.td(td_attrs[i]) do
                       if raw_cols[i]
                         h.raw!(r[ci])
                       else
                         h.text(r[ci])
                       end
                     end
                   end
                 end
               end
             end
           end
           x = opts[:body_foot] and h.raw!(x)
         end
         
         h.js(read_content_once("tablesort.js"))
         h.js(read_content_once("filter.js"))
         h.js("new Tablesort(document.getElementById('cx-table'));")
         h << read_content('footer.html')
         end
        end
        env[:content_type] = 'text/html'
        output
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

