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
    attr_accessor :argv, :args, :opts

    def initialize argv = []
      @argv = argv.map(&:dup)
      # @apps = [ ]
      initialize!
    end

    def initialize!
      args = Args.new
      args.parse!(argv)
      @argv = args.argv
      @args = args.args
      @opts = args.opts
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
    
    module SelectColumns
      include Xform
      def initialize!
      end
    end
  end
end
  
