# frozen_string_literal: true

require 'cx'
require 'cx/args'
require 'cx/inspect'
require 'cx/xform/pipeline'
require 'cx/command_factory'

module CX
  class PipelineBuilder
    include Support
    
    attr_accessor :pipeline, :global, :factory

    def parse! argv
      @argv = argv
      @pipeline = parse_pipeline!
      @global = @pipeline.args
      @argv = nil
      self
    end
    alias :call :parse!
    
    def parse_pipeline!
      args = Args.new.parse!(
        @argv,
        no_args: true,
        terminator: Proc.new { |arg|
          %r{\A(//|{{|}})\Z}.match(arg)
        }
      )
      pipeline = Pipeline.new(args)
      parse_argv! pipeline
      pipeline
    end
    
    def parse_argv! pipeline
      pending = []
      until @argv.empty?
        case @argv.first
        when '//'
          @argv.shift
          add_command!(pipeline, pending)
          pending = [ ]
        when '{{'
          @argv.shift
          pending << parse_pipeline!
        when '}}'
          @argv.shift
          break
        else
          pending << @argv.shift
        end
      end
      add_command!(pipeline, pending)
    end

    def add_command! pipeline, argv
      unless argv.empty?
        args = Args.new.parse!(argv.dup)
        raise CX::Error, "command without name #{argv * ' '}" if ! args.opts.empty? && args.argv.empty?
        pipeline << Command.new(args) unless args.argv.empty?
      end
    end
    
    def build_xform
      @factory ||= CommandFactory.new.load!
      @pipeline.build_xform(@factory)
    end
    
    class Command < Struct.new(:args)
      include Support
      def build_xform factory
        args.argv.map! do | arg |
          case arg
          when Pipeline, Command
            arg.build_xform factory
          else
            arg
          end
        end
        factory.call(args)
      end
      def inspect_content mode
        "#{args.inspect}"
      end
    end

    class Pipeline < Struct.new(:args, :commands)
      include Support
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

