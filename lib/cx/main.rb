#!/usr/bin/env ruby
# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8

# cx: Copyright 2020, Kurt Stephens

require 'cx'
require 'cx/logging'
require 'cx/util'
require 'cx/command'
require 'cx/table'
require 'cx/header'
require 'cx/typing'
require 'cx/pipe'
require 'cx/io'
require 'cx/misc' # AUTOLOAD!
require 'set'
require 'shellwords'
require 'tempfile'
require 'thread'
require 'pp'

######################################

module CX
# Main command line driver.
class Main
  include Logging
  extend Logging
  Logging.raise_cls = Error

  attr_accessor :progname, :args, :opts, :env, :pipeline, :exit_code
  
  def initialize args
    @progname = File.basename($0)
    @args = args.map(&:dup)
    @exit_code = 0
    @opts = { }
    @env = { }
    @verbose = false
  end

  def run!
    log.level = Logger::WARN
    @env = {
      main: {
        progname: $0,
        ARGV: args,
        # ENV: ENV,
        t0: Time.now,
      }
    }
    
    args = self.args.map(&:dup)
    @env_opts = Shellwords.shellsplit(ENV['CX_OPTS'] || '')
    args = @env_opts + args
    @opts = parse_opts! args
    env[:opts] = opts
    
    @verbose = opts[:verbose]
    @debug = @opts[:debug]
    CX::Logging.debug = @debug
    log.level = Logger::INFO  if @verbose
    log.level = Logger::DEBUG if @debug
    
    case
    when opts[:help]
      help!
      exit 0
    when opts[:_test___]
      test!
    when opts[:_pry___]
      if opts[:_break___]
        binding.pry
        :stopped_here
      end
    end

    @pipeline = parse_pipeline! args
    env[:main][:commands] = @pipeline

    pp(pipeline: @pipeline) if @debug
    @app = make_pipeline @pipeline

    go!

    self
  rescue => exc
    log.error "#{progname} : #{exc.inspect}"
    log.info { (["backtrace:::"] + exc.backtrace.reverse + [":::"]).join("\n") }
    @exit_code = 1
    self
  ensure
    GC.start(full_mark: true, immediate_sweep: true)
  end

  # Starts application command pipeline.
  def go!
    @app.run! env
    self
  end

  # TODO: use an option parse library?
  def parse_opts! args
    opts = { }
    while arg = args.first
      case arg
      when /^--([^=]+)=(.*)$/
        k, v = $1, $2
      when /^--([^=]+)$/
        k, v = $1, 1
      when /^\+\+([^=]+)$/
        k, v = $1, -1
      when '--'
        args.shift
        break
      else
        break 
      end
      k = k.gsub('-', '_').to_sym
      if Numeric === v
        x = (opts[k] || 0) + v
        v = false if v <= 0
      end
      opts[k] = v
      args.shift
    end
    opts
  end

  ###################################
  # Parse pipeline
  #
  
  def parse_pipeline! args
    pipeline = [ ]
    pp(parse_pipeline!: args) if @debug
    while arg = args.shift
      case arg
      when '//'
      else
        args.unshift arg
        pipeline << parse_cmd!(args)
      end
    end
    raise_ "empty pipeline #{self.args.inspect}" if pipeline.empty?
    pipeline.extend(Pipe::Pipeline)
    # pp(pipeline: pipeline)
    pipeline
  end

  def parse_cmd! args
    name = args.shift.to_sym
    opts = parse_opts! args
    cmd = [ name, cmd_args = [ ], opts ]
    while arg = args.shift
      case arg
      when '//'
        break
      when '{{'
        cmd_args << parse_pipeline!(args)
      when '}}'
        args.unshift nil # sentinel for parse_pipeline!
        break
      else
        cmd_args << arg
      end
    end
    cmd
  end

  ###################################
  # Build pipeline
  #
  
  # Applications are right folded.
  # If input/output applications are unspecified,
  # STDIN and STDOUT are wrapped the pipeline.
  def make_pipeline pipeline
    unless Command.factory(pipeline[0][0])  <= Pipe::In
      pipeline.unshift([:in, [$stdin]])
    end
    unless Command.factory(pipeline[-1][0]) <= Pipe::Out
      pipeline.push([:out, [$stdout]])
    end
    pp(pipeline: pipeline) if @debug
    app = reduce_pipeline app, pipeline
    app
  end

  def reduce_pipeline app, pipeline
    pipeline.reverse.inject(app) do |app, spec|
      make_cmd app, spec
    end.extend(Pipe::Pipeline)
  end
  
  def make_cmd app, cmd
    name, args, opts = cmd
    pp(make_cmd: [app, cmd]) if @debug    
    args.map! do |arg|
      Pipe::Pipeline === arg ? reduce_pipeline(nil, arg) : arg
    end
    new_app = Command.factory(name).new(app, args, opts)
    new_app = HeaderIn.new(new_app) if Pipe::NeedsHeader === new_app
    new_app = Debug.new(new_app) if @debug
    new_app
  end

  def test!
    require 'cx/help_and_test'
    unit_test!
    CX::HelpAndTest.test!(opts)
    exit 0
  end
  
  def help!
    require 'cx/help_and_test'
    HelpAndTest.help!
  end
  
  def inspect
    "#<#{self.class} #{args.inspect}>"
  end
end

end

##################################
# EOF

