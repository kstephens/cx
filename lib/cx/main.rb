#!/usr/bin/env ruby
# frozen_string_literal: true

# cx: Copyright 2020, Kurt Stephens

require 'cx'
require 'cx/version'
require 'cx/logging'
require 'cx/util'
require 'cx/xform'
require 'cx/args'
require 'cx/table'
require 'cx/header'
require 'cx/error'
require 'cx/xform'
require 'cx/xform/pipeline'
require 'cx/command_factory'
require 'cx/pipeline_builder'
require 'cx/xform/io'
require 'cx/xform/csv'
require 'set'
require 'shellwords'
require 'tempfile'
require 'thread'
require 'pp'

######################################

module CX
  # Main command line driver.
  class Main
    include Support
    
    Error::Support.raise_cls = ::CX::Error

    attr_accessor :progname, :argv, :args, :opts, :env, :pipeline, :exit_code

    def initialize argv
      @verbose = false
      @progname = File.basename($0)
      @exit_code = 0
      @argv = argv.map(&:dup)
      @args = [ ]
      @opts = { }
      @env = {
        main: {
          progname: @progname,
          cwd: Dir.pwd,
          argv: argv.map(&:dup),
          args: :UNKNOWN,
          opts: :UNKNOWN,
          debug: false,
          verbose: false,
          t0: Time.now,
          exit_code: 0,
        },
      }
      log.level = Logger::WARN
    end

    def parse_argv!
      @env[:main][:env_args] = @env_args = Shellwords.shellsplit(ENV['CX_OPTS'] || '')
      @env[:main][:argv_full] = @argv_full = @env_args + @argv
      @env[:main][:parsed_args] = @parsed_args = Args.new.parse!(@argv_full, no_args: true)
      @env[:main][:args] = @args = @argv_full
      @env[:main][:opts] = @opts = @parsed_args.opts
      @env[:main][:verbose] = @opts[:verbose]
      @env[:main][:debug] = @debug = @opts[:debug]
      
      CX::Debug.debug = @debug
      log.level = Logger::INFO  if @verbose
      log.level = Logger::DEBUG if @debug
      self
    end
    
    def run!
      parse_argv!

      case
      when opts[:help]
        help!
        exit 0
      when opts[:version]
        puts CX::VERSION
        exit 0
      when opts[:_test___]
        test!
      when opts[:_pry___]
        if opts[:_break___]
          binding.pry
          :stopped_here
        end
      end

      @factory = factory = CommandFactory.new.load!
      env[:main][:defaults].
        update(input_format:
               lambda do
                 @factory.new(Args.new.parse!(['-csv']))
               end,
               output_format:
                 lambda do
                 @factory.new(Args.new.parse!(['csv-']))
               end
              )
      
      setup_pipeline!
      env[:main][:pipeline] = @pipeline

      go!

      self
    rescue => exc
      log.error "#{progname} : #{exc.inspect}"
      log.error { (["backtrace:::"] + exc.backtrace.reverse + [":::"]).join("\n") }
      @exit_code = @env[:main][:exit_code]
      self
    ensure
      GC.start(full_mark: true, immediate_sweep: true) if @full_gc
    end

    # Starts application command pipeline.
    def go!
      @pipeline.call(Table.new, env)
      self
    end

    def setup_pipeline!
      @pipeline = parse_pipeline! @args

      @pipeline.default_io!
      @pipeline.default_format!(@env[:main][:defaults])
      
      pp(pipeline: @pipeline) if @debug
      raise_ "empty pipeline #{self.args.inspect}" if pipeline.empty?
      self
    end
    
    def parse_pipeline! pipeline_args
      pp(pipeline_args!: pipeline_args) if @debug
      @builder = PipelineBuilder.new
      @builder.factory = @factory
      @builder.parse!(pipeline_args)
      # binding.pry
      pipeline = @builder.build_xform      
      pipeline
    end

    def test!
      require 'cx/help_and_test'
      unit_test!
      CX::HelpAndTest.test!(opts)
      exit 0
    end

    def help!
      require 'cx/help_and_test'
      CX::HelpAndTest.help!
    end
  end
end

##################################
# EOF

