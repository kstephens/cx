# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/error'
require 'cx/debug'
require 'cx/inspect'
require 'cx/logging'
require 'cx/args'

module CX
  module Xform
    include Error::Support, Debug, Inspect, Logging

    def build argv = []
      set_args! Args.new.parse!(argv)
    end
    
    def initialize
      @_args = Args.new
    end

    def initialize!
      self
    end

    def call input, env
      raise_ "call : not implemented"
    end
    
    def argv ; @_args.argv ; end
    def args ; @_args.args ; end
    def opts ; @_args.opts ; end

    def set_args! args
      @_args = args
      initialize!
      self
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
        opts.fetch(:include_header, true)
      end
    end
    
    module SelectColumns
      include Xform
      def initialize!
        super
        # TODO
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
  
