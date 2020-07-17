# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/logging'

module CX
  # Registry of commands
  module Command
    extend self
    include Logging
    extend Logging
    
    COMMANDS = { }
    def cmd *args
      name, *aliases = args[0]
      
      case name.to_s
      when /^[A-Z]/
        class_name = args.shift
        name, *aliases = args.shift
      end
      
      case name
      when /^-(.*)$/
        class_name ||= name[1].upcase + name[2 .. -1] + "In"
      when /^(.*)-$/
        class_name ||= name[0].upcase + name[1 .. -2] + "Out"
      else
        class_name ||= name[0].upcase + name[1 .. -1]
      end

      class_name = class_name.to_sym
      
      _, synopsis, options, path = args
      synopsis  ||= ""
      options   ||= {}
      
      path ||= name.to_s.gsub(/\W/, '')
      path =  "cx/#{path}"
      spec =
        {
        name: name,
        aliases: aliases,
        synopsis: synopsis,
        options: options,
        help: nil,
        examples: [],
        class_name: class_name,
        class: nil,
        path: path,
        }
      [name, *aliases].each do | n |
        COMMANDS[n.to_sym] = spec
      end
      # CX.autoload class_name, path
    end
    
    def spec name
      COMMANDS[name.to_sym] or raise_ "unknown command: #{name.inspect} : run 'cx --help'"
    end
    
    def _factory s
      unless f = s[:class]
        begin
          log.debug "Loading #{s[:path].inspect}"
          require s[:path]
        rescue LoadError
          # Assume it's in main.rb
        end
        f = s[:class] = CX.const_get(s[:class_name])
      end
      f
    end
    
    def factory name
      _factory(spec(name))
    end
    
    ################################

    cmd :IOIn,  [ :in,  :r, :i ], 'read from a file   If unspecfied, use STDIN.'
    cmd :IOOut, [ :out, :w, :o ], 'write to a file   If unspecfied, use STDOUT.'

    cmd :debug,
      'emits debug information during processing   If --table, dump input/output tables.'

    cmd [ :"-header", :'-h' ],
      'capture column header from first row  Typically used after "-csv".'
    cmd [ :"header-", :'h-',],
      'emit column names in first row   Typically used before "csv-".'

    cmd :grep,
      'emit rows matching specified column regexs'
    cmd [ :transpose, :xpose ],
      'transpose table'
    cmd [ :region, :range ],
      'emit regions of rows   E.g: "1" for first row, "-2" 2nd from last, "2..10".'
    cmd :cut,
      'emit specified columns   "@" represents all columns, columns can be reordered: "b,@", or deleted: "@,b-".'
    cmd :sort,
      'sort by specified columns   Columns specified with ":-" option will sort in reverse.'
    cmd :uniq,
      'emit unique rows   Specified rows delimit uniqness.'

    cmd :eval,
      'evaluate Ruby expression for each row   Assignments to "self" (or "_") update values.  Assignments to non-existant header columns results in new columns.'
    cmd [ :cmd, :- ],
      'pipe rows thru an external command.  Column references "%NAME%" are replaced with column index + 1.'
    
    cmd [ :"columns", :"cols=" ],
      'Define columns   Specify/override column names and options.'
    cmd [ :"columns-", :"cols-" ],
      'emit header column attributes'
    cmd :types,
      'infer column types from values   Empty strings or nil values are considered inconclusive.'
    cmd :coerce,
      "coerce values into derived or specified types."
    
    cmd [ :'tee', :t ],
      'duplicate input to one or more output pipelines.'
    cmd [ :'join', :j ],
      'Join on values between one or more pipelines.'

    cmd :'-csv', 'parse CSV lines'
    cmd :'csv-', 'emit CSV lines'

    cmd [ :'txt-', :'t-', :ascii, :text ],
      'emit formatted text table'
    cmd [ :'markdown-' , :'md-'],
      'emit Markdown table'
    cmd [ :'html-', :html ],
      'emit HTML table document.', {
      '--title=' => 'Specify a <title>.',
      '--filtering' => 'Add a full-text filtering field.',
      '--raw=' => 'A list of columns that contain raw HTML.',
      '--head=' => 'Raw HTML placed at bottom of <head>.',
      '--body-head=' => 'Raw HTML placed at the top of <body>.',
      '--body-foot=' => 'Raw HTML placed at bottom of <body>.',
    }

    cmd :'-json',            'parse JSON'
    cmd [ :'json-', :json ], 'emit JSON'
    cmd [ :'edn-', :edn, :clj, :'clj-' ],
      'emit EDN   EDN is native to Clojure.'
    cmd :'-yaml',            'parse YAML'
    cmd [ :'yaml-', :yaml ], 'emit YAML'
    cmd :'sql-',
      'Generate INSERT INTO or CREATE TABLE SQL statements   '
    # binding.pry
  end
end
