# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/args'
require 'cx/xform/pipeline'

module CX
  class PipelineBuilder
    attr_accessor :argv, :commands, :global, :pipeline, :factory

    def parse! _argv
      @argv = _argv.map(&:dup)

      @commands = [ ]
      command = [ ]

      @global = Args.new.parse!(argv, no_args: true)
      args = @global.args + [nil]
      @global.args = []
      args.each do | arg |
        case arg
        when '//', nil
          commands << Args.new.parse!(command) unless command.empty?
          command = [ ]
        else
          command << arg
        end
      end
      self
    end
    
    def build_pipeline
      @factory ||= CommandFactory.new.load!
      @pipeline = Xform::Pipeline.new
      commands.each do | args |
        @pipeline >> build_xform(args)
      end
      self
    end
    
    def build_xform argv
      @factory.call(argv)
    end
  end
end

