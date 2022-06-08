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
require 'cx/measured'

######################################

module CX
  # Main command line driver.
  class Main
    include Support
    
    Error::Support.raise_cls = ::CX::Error

    attr_accessor :progname, :argv, :args, :opts, :env, :factory, :pipeline, :exit_code

    Logging.log.level = Logger::WARN

    def initialize argv
      now = Time.now
      @t0 = $cx_t0 || now
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
          cmd_argv: argv.map(&:dup),
          env_argv: [],
          full_argv: argv.map(&:dup),
          args: :UNKNOWN,
          opts: :UNKNOWN,
          debug: false,
          verbose: false,
          exit_code: 0,
          #
          started_at: @t0,
          main_started_at: now,
          main_finished_at: nil,
          start_elapsed_ms: ((now - @t0) * 1000).to_i,
          total_elapsed_ms: nil,
          main_elapsed_ms: nil,
          #
          defaults: {
          },
          trace: {
            in:  Hash.new{|h,k| h[k] = []},
            out: Hash.new{|h,k| h[k] = []},
          },
          stats: {
            in:  Hash.new{|h,k| h[k] = 0},
            out: Hash.new{|h,k| h[k] = 0}
          },
        },
      }
    end

    def parse_argv!
      env[:main][:env_argv] = @env_args = Shellwords.shellsplit(ENV['CX_OPTS'] || '')
      env[:main][:full_argv] = (@full_argv = @env_args + @argv).dup
      env[:main][:parsed_args] = @parsed_args = Args.new.parse!(@full_argv, no_args: true)
      env[:main][:args] = @args = @full_argv
      env[:main][:opts] = @opts = @parsed_args.opts
      env[:main][:verbose] = opts[:verbose]
      env[:main][:debug] = @debug = opts[:debug]
      env[:main][:info]  = opts[:info]
      
      CX::Debug.debug = debug
      CX::Debug.verbose = verbose
      
      level = Logger::WARN
      level = Logger::INFO if verbose || opts[:info]
      level = Logger::DEBUG if debug
      log.level = level

      self
    end

    def run!
      run_unsafe!
    rescue => exc
      # binding.pry if debug?
      msg = progname.dup
      reason = exc.reason rescue nil
      data = exc.data rescue nil
      msg << exc.message
      msg << "\nreason: #{reason}" if reason
      msg << "\nin: #{data}" if data
      if debug?
        msg << (["\nbacktrace ::::"] + exc.backtrace.reverse + ["::::"]).join("\n")
      end
      log.error msg
      @exit_code = env[:main][:exit_code]
      self
    ensure
      $stderr.puts pps(env: env) if opts[:show_env]
      GC.start(full_mark: true, immediate_sweep: true) if @full_gc
    end

    def run_unsafe!
      parse_argv!

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

      case
      when opts[:help]
        args.unshift 'help'
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

      setup_pipeline!
      env[:main][:pipeline] = @pipeline
      # pp(pipeline_argv: @pipeline.pipeline_argv) if debug?

      @pipeline.call(Table.new, env)

      self
    ensure
      now = Time.now
      (h = env[:main]).
        update(main_finished_at: now,
               total_elapsed_ms: ((now - @t0) * 1000).to_i,
               main_elapsed_ms:  ((now - h[:main_started_at]) * 1000).to_i,
              )
    end

    def setup_pipeline!
      @pipeline = parse_pipeline! @args

      @pipeline.default_io!
      @pipeline.default_input_format!(env[:main][:defaults][:input_format])
      @pipeline.default_output_format!(env[:main][:defaults][:output_format])
      
      # pp(pipeline: @pipeline) if debug?
      raise_ "empty pipeline #{self.args.inspect}" if pipeline.empty?
      self
    end
    
    def parse_pipeline! pipeline_args
      # pp(pipeline_args!: pipeline_args) if @debug
      @builder = PipelineBuilder.new
      @builder.factory = @factory
      @builder.parse!(pipeline_args)
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

