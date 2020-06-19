# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/pipe'
require 'stringio'
require 'open3'

module CX
# Base class for IO.
class IOPipe < Pipe
  def open arg
    io = nil
    reraise do
      case arg
      when String, File
        io = File.open(arg.to_s, io_mode)
      when IO, StringIO
        io = arg
      else
        raise_ "Invalid IO argument: #{arg.inspect}"
      end
    end
    yield io
  ensure
    io.close if close?(io)
  end
  
  def with_io arg
    @lineno = 0
    @line = nil
    open(arg) do | io |
      begin
        yield io
      rescue => exc
        raise_ "line #{@lineno.inspect} : #{@line.inspect} : #{@io_.inspect}", exc
      end
    end
  end

  def close? io
    io && io.respond_to?(:close) && 
      ! [ $stdin, $stdout, $stderr,
          STDIN,  STDOUT,  STDERR ]
        .map(&:fileno).include?(io.fileno)
  end
end

class IOIn < IOPipe
  include In
  def io_mode ; "r" ; end
  def call input, env
    debugQ = debug?
    output = new_table(input)
    args.each do | arg |
      with_io(arg) do | io |
        until io.eof?
          @lineno += 1
          @line = io.readline
          pp(self: self, line: @line) if debugQ
          output << @line
        end
      end
    end
    app.call(output, env)
  end
end

class IOOut < IOPipe
  include Out
  def init_more!
    super
    raise_ "requires one output argument : #{args.inspect}" unless args.size == 1
  end
  def io_mode ; "w" ; end
  def call input, env
    with_io(args.first) do | io |
      pp(input: input) if debug?
      input.each_shift do |e|
        @lineno += 1
        @line = e
        io.write e
      end
    end
    app && app.call(input, env)
  end
  def write x
    io.write x.to_s
    self
  end
  alias :<< :write
end

end
