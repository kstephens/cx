# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/inspect'

module CX
  class Args
    include Inspect
    attr_accessor :args, :opts, :argv

    def initialize
      @args = [ ]
      @opts = { }
      @argv = [ ]
    end

    def initialize_copy orig
      super
      @args = @args.dup
      @opts = @opts.dup
      @argv = @argv.dup
    end
    
    def parse! input, options = { }
      @input = input
      @no_args = options[:no_args]
      @terminator = options[:terminator] || Proc.new{|x| false}
      catch(:stop!) do
        each_input! do | arg |
          case arg
          when String
            case arg
            when /^--no-([-_a-z0-9]+)$/i
              set_opt! $1, false
            when /^--([-_a-z0-9]+)$/i
              set_opt! $1, true
            when /^--([-_a-z0-9]+)=(.*)$/i
              set_opt! $1, $2
            else
              arg! arg
            end
          else
            arg! arg
          end
        end
      end
      @input = nil
      self
    end
    
    alias :call :parse!

    def each_input!
      loop do
        case arg = take_arg!
        when '--'
          loop do
            arg! take_arg!
          end
        else
          yield arg
        end
      end
    end

    def take_arg!
      arg = @input.first
      case
      when @input.empty?
        throw :stop!
      when @terminator.call(arg)
        throw :stop!
      else
        @argv << arg
        @input.shift
        arg
      end
    end

    def arg! arg
      if @no_args
        @argv.pop
        @input.unshift arg
        throw :stop!
      else
        @args << arg
      end
    end

    def set_opt! key, val
      @opts[key.gsub(/-/, '_').to_sym] = val
    end

    def to_h
      {
        opts: @opts,
        args: @args,
        argv: @argv,
      }
    end

    alias :to_a :argv

    def inspect_content mode
      "#{opts.inspect} #{args.inspect}"
    end
  end
end

