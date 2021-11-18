# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/inspect'
require 'cx/args'
require 'cx/logging'

module CX
  module Xform
    include Inspect, Logging

    def initialize _argv = []
      @_argv = _argv && _argv.map(&:dup) # .map(&:freeze)
      @_args = Args.new
      initialize!
    end

    def initialize!
      @_args.parse!(@_argv) if @_argv
      self
    end

    def argv ; @_args.argv ; end
    def args ; @_args.args ; end
    def opts ; @_args.opts ; end
    
    def parse_args! argv = nil
      arg=v ||= @_argv
      @_args.parse!(argv) if argv
      @argv = @_args.argv
      @args = @_args.args
      @opts = @_args.opts
    end
    
    def debug? ; false ; end

    def >> app
      Pipeline.new >> app
    end

    module Format
      # TODO:
      include Xform
    end

    module InputFormat
      include Format
    end
    
    module OutputFormat
      include Format
      def include_header?
        opts.or_default(:include_header, true)
      end
    end
    
    module SelectColumns
      include Xform
      def initialize!
      end
    end

    def self.require_all!
      lib_dir = File.expand_path('../../', __FILE__) + '/'
      files = Dir["#{lib_dir}cx/xform/*.rb"]
      requires = files.map{|f| f.sub(lib_dir, '').sub(/\.rb$/, '') }
      # pp(files: files, requires: requires)
      requires.each{|r| require r}
    end
  end
end
  
