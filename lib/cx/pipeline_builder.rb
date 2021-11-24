# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/args'
require 'cx/inspect'
require 'cx/xform/pipeline'

module CX
  class PipelineBuilder
    attr_accessor :argv, :pipeline, :global, :factory

    def parse! _argv
      @argv = _argv.dup
      @pipeline = parse_pipeline! @argv.dup
      @global = @pipeline.args
      self
    end

    def parse_pipeline! argv
      opts = Args.new.parse!(argv, no_args: true)
      argv[0 .. -1] = opts.args
      opts.args = []
      parse_args! argv, Pipeline.new(opts)
    end
    
    def parse_args! args, pipeline
      pending = [ ]
      while arg = args.shift
        case arg
        when nil
        when '//'
          pipeline << Command.new(pending) unless pending.empty?
          pending = [ ]
        when '{{'
          pending << parse_pipeline!(args)
        when '}}'
          break
        else
          pending << arg
        end
      end
      pipeline << Command.new(pending) unless pending.empty?
      pipeline
    end
    
    def build_xform
      @factory ||= CommandFactory.new.load!
      @pipeline.build_xform(@factory)
    end
    
    class Command < Struct.new(:argv, :args)
      include Inspect
      def initialize argv
        self.argv = argv
        self.args = Args.new.parse!(argv)
      end
      
      def build_xform factory
        args = Args.new.parse!(
          argv.map do | arg |
            case arg
            when Pipeline, Command
              arg.build_xform factory
            else
              arg
            end
          end
        )
        factory.call(args)
      end
      def inspect_content mode
        "#{args.inspect}"
      end
    end

    class Pipeline < Struct.new(:args, :commands)
      include Inspect
      def initialize *args
        super
        self.commands ||= [ ]
      end
      
      def << command
        self.commands << command
        self
      end
      
      def build_xform factory
        xform = Xform::Pipeline.new
        commands.each do | command |
          xform >> command.build_xform(factory)
        end
        xform
      end
      def inspect_content mode
        "#{args.inspect} #{commands.inspect}"
      end
    end
  end
end

