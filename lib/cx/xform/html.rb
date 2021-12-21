# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'cx/io_buffer'
require 'cx/html_markup'

# :COMMAND:
# HtmlOut:
#   aliases: html,htm
#   synopsis: 'Emits HTML.'
#   suffixes: [ .html, .htm ]
#   args: []
#   opts:
#     title:      'Sets the HTML `title`.'
#     table-only: 'Emit the HTML `table` only.'
#     filtering:  'Enable filtering.  Default: true'
#     sorting:    'Enable sorting.  Default: true'
#     styled:     'Enable styling.  Default: true'
#     raw:        'Comma-separated list of columns that contain raw HTML.'
#     head:       'Additional raw HTML at foot of `head`.'
#     body-head:  'Additional raw HTML at head of `body`.'
#     body-foot:  'Additional raw HTML at foot of `body`.'
#     indent:     'Spaces to indent.  Default: 1'

module CX
  module Xform
    class HtmlOut
      include SelectColumns, OutputFormat, RecordOut
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

      attr_reader :input, :env
      attr_reader :h, :colspan, :cols, :col_data, :header, :right
      
      def call_ input, env, out
        @input, @env = input, env
        @header = input.header
        @cols = column_args!(input).or_all!.columns.sort_by(&:order)
        @colspan = 1 + cols.size
        @right = {class: 'cx-right'}
        # @h = XMLWriter.new(out, indent: opts[:indent])
        @h = CX::HtmlMarkup.new(target: out, indent: @indent)
        @h.file_content_path = File.expand_path("../html", __FILE__)
        @h.attrs_enabled = @styled || @sorting || @filtering
        @col_data = Hash.new{|h, k| h[k] = {}}

        cols.each do | c |
          data = col_data[c]
          data[:class] = right[:class] if c.meta.align_ == :right
        end

        root!
        out.flush

        @input, @env = @header = @cols = @h = @col_data = nil
        
        env[:content_type] = 'text/html'
      end

      #########################################
      
      def root!
        if @table_only
          table!
        else
          document! do
            table!
          end
        end
      end

      def document!
        h.raw! "<!DOCTYPE html>\n"
        
        h.html do
          h.head do
            h.meta(charset: "UTF-8")
            if x = opts[:title] || env[:in_file] 
              h.title(x);
            end
            if @styled
              h.css! h.file_content!('cx.min.css')
            end
            h.html! h.file_content!('head.html')
            optional_content(:head) {|x| raw!(x) }
          end
          h.body do
            optional_content(:body_head) {|x| raw!(x)}
            h.div(class: 'cx-content') do
              x = opts[:title] and h.div({class: 'cx-title'}, x)
              yield
            end
            optional_content(:body_foot) {|x| raw!(x)}
          end
          raw! h.file_content!('foot.html')
        end
      end

      def table!
        optional_content(:table_head) {|x| raw!(x)}
        h.table(id: 'cx-table', class: 'cx-table') do
          thead! if include_header?
          tbody!
        end
        optional_content(:table_foot) {|x| raw!(x)}
        table_footer!
      end

      #########################################################

      attr_accessor :col_idx
      
      def thead!
        h.thead(class: 'cx-thead') do

          thead_filtering! if opts[:filtering]
          
          h.tr(class: 'cx-columns') do
            a_base = {class: 'cx-column'}
            a_row_number = a_base
            if @sorting
              a_row_number = a_row_number.merge("data-sort-method" => :number)
            end
            h.th(a_row_number, "#")
            self.col_idx = 0
            cols.each do | c |
              self.col_idx += 1
              thead_col! c, a_base
            end
          end
        end
      end

      def thead_col! c, a
        if @filtering
          a = a.merge(
            "data-column-index" => col_idx,
            "data-filter-name" => c.name_.to_s,
            "data-filter-name-full" => c.name.to_s)
        end
        if @sorting
          a = a.merge("data-sort-method" => :number) if c.meta.align_ == :right
        end
        
        names = [ c.name, c.name_ ].map(&:to_s).sort.uniq.map(&:inspect).join(', ')
        
        td_title = <<"END".sub(/\n\Z/, '') # .gsub("\n", "&#10;")
name: #{names}
index: #{col_idx}
type: #{c.meta.type_ || :UNKNOWN}
END
        td_title = "name: #{names}; index: #{col_idx}; type: #{c.meta.type_ || :UNKNOWN}"
        a = a.merge(title: td_title)

        h.th(a, c)
      end

      #########################################################
      
      attr_accessor :row_idx
      
      def tbody!
        h.tbody(class: 'cx-tbody') do
          self.row_idx = 0
          input.each do | r |
            self.row_idx += 1
            tbody_tr! r
          end
        end
      end

      def tbody_tr! r
        row_tooltip = "#{row_idx} / #{input.size}"
        # row_tooltipe << ": #{r[inds[0]]}" # TODO: make this optional
        h.tr(title: row_tooltip) do
          row_id = "r#{row_idx}"
          # link to row:
          # FIXME: scrolls row to top of frame which is under the thead!!!
          if false
            h.td(right.merge(id: row_id)) do
              h.a({href: "\##{row_id}"}, row_idx)
            end
          else
            # h.td((right.merge(id: row_id)}, row_idx);
            h.td(right, row_idx);
          end
          
          cols.each do | c |
            attrs = col_data[c].merge(title: "#{row_tooltip} - #{c.name}")

            h.indent!(false) do
              h.td(attrs) do
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
      
      def thead_filtering!
        h.tr(class: 'cx-filter-row') do
          h.th(colspan: colspan) do
            h.indent!(false) do
              h.span(class: 'cx-filter-input-span') do
                h.input(
                  type: "text",
                  id: "cx-filter-input",
                  class: "cx-filter-input",
                  onkeyup: "cx_filter.filter_rows(event)",
                  placeholder: "#{UNICODE[:search]} Filter..."
                )
                # Clear filter button:
                if true
                  h.button({class: 'cx-filter-input-clear', onclick: 'cx_filter.clear_filter()'}, 'X')
                end
                h.span(class: 'cx-filter-row-count-span') do
                  h.span({class: 'cx-filter-matched-row-count'}, input.size.to_s)
                  h.text!(' / ')
                  h.span({class: 'cx-filter-row-count'}, input.size.to_s)
                end
              end
            end
          end
        end
      end
      
      def table_footer!
        if @filtering
          h.js! h.file_content!("vendor/zepto.min.js")
          h.js! h.file_content!("parser_combinator.min.js")
          h.js! h.file_content!("filter.min.js")
        end
        if @sorting
          h.js! h.file_content!("vendor/tablesort.js")
          h.js! "new Tablesort(document.getElementById('cx-table'));\n"
          h.js! "var cx_filter = cx_make_filter('cx-table');\n"
        end
      end

      ########################################

      def optional_content name, default = nil
        case content = opts[name]
        when /^@(.*)/
          content = File.read(content)
        end
        content ||= default
        yield content if content && block_given?
        content
      end
      
      ########################################

      def raw! x
        h.raw! x.to_s
      end
      
      def text! x
        raw! @coerce.call(x).to_s
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
        when String
          case
          when false ## @quote_strings
            case x
            when /[ \\"']/
              x.inspect
            else
              x
            end
          else
            x
          end
        else
          x.to_s
        end
      end
      
     UNICODE = {
       # Left-Pointing Magnifying Glass : U+1F50D
       search: "🔍",
     }
    end
  end
end

