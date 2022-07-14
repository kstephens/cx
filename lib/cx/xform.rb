# frozen_string_literal: true

require 'cx'
require 'cx/args'
require 'cx/column_args'

module CX
  module Xform
    include Support

    def build argv = []
      set_args! Args.new.parse!(argv)
    end
    
    def initialize
      @_args = Args.new
    end

    def initialize!
      self
    end

    def call input, env
      raise_ "call : not implemented"
    end

    attr_accessor :progname 
    def argv ; @_args.argv ; end
    def args ; @_args.args ; end
    def opts ; @_args.opts ; end

    def set_args! args
      @_args = args
      initialize!
      self
    end

    def >> app
      Pipeline.new >> app
    end

    def pipeline_argv argv = self.argv
      argv.map{|x| Xform === x ? x.pipeline_argv : x}
    end

    module Format ; end
    module InputFormat
      include Format
    end
    module OutputFormat
      include Format
      def include_header?
        opts.fetch(:include_header, true)
      end
    end

    module PipelineArgs
      attr_accessor :pipeline_args

      def pipeline_args! args = self.args
        @pipeline_args, other_args = args.partition{|x| Xform === x}
        args[0 .. -1] = other_args
        @pipeline_args
      end
    end
    
    module SelectColumns
      attr_accessor :column_argv, :column_args, :selected_columns
      
      def parse_args!
        @column_args =
          ColumnArgs.new.
          parse!(column_argv || args)
      end
      def column_args! input
          parse_args!.bind!(input.header).
          wildcards!
      end
    end

    def self.require_all!
      lib_dir = File.expand_path('../../', __FILE__) + '/'
      files = Dir["#{lib_dir}cx/xform/*.rb"]
      requires = files.map{|f| f.sub(lib_dir, '').sub(/\.rb$/, '') }
      # pp(files: files, requires: requires)
      requires.each{|r| require r}
    end
  end
end
  
