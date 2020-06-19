# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'open3'

module CX
  class Cmd < Pipe
  include Pipe::Process
  attr_accessor :command

  def init_more!
    super
    @command = args
    @column_offset = (opts[:column_offset] || 1).to_i
    @m = Mutex.new
  end
  def inspect_pipe mode = nil
    @command.inspect
  end
  
  def call input, env
    stdin = stdout = wait_thr = wt = rt = nil
    reraise do
      output = new_table(input)
      cmd = command
      if header = input.header 
        rx = Regexp.new("%(" + header.map{|c| Regexp.quote(c.to_s)} * '|' + ")%")
        cmd = cmd.map do | arg |
          arg.gsub(rx){|m| header[$1.to_sym].to_i + @column_offset}
        end
      end
      stdin, stdout, wait_thr = Open3.popen2(*cmd)
      wt = writer! input , stdin
      rt = reader! output, stdout
      wt.join
      rt.join
      wait_thr.value # Fail on command exit code ???
      app.call(output, env)
    end
  ensure
    stdin.close  rescue nil
    stdout.close rescue nil
    wt.kill      rescue nil
    rt.kill      rescue nil
    unless $!
      raise_ wt[:name], wt[:exc] if wt && wt[:exc]
      raise_ rt[:name], rt[:exc] if rt && rt[:exc]
    end
  end

  def writer! input, io
    Thread.new do
      Thread.current[:name] = "#{self.class} writer"
      with_io io do
        input.each_shift do | e |
          io.write e.to_s
        end
      end
    end
  end
  
  def reader! output, io
    Thread.new do
      Thread.current[:name] = "#{self.class} reader"
      with_io io do
        until io.eof?
          line = io.readline
          output << line
        end
      end
    end
  end
  
  def with_io io
    yield
  rescue => exc
    Thread.current[:exc] = exc
    raise
  ensure
    io.close
  end

  def pp *args
    @m.synchronize do
      super
    end
  end
end

end
