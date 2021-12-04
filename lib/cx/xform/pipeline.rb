# frozen_string_literal: true

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class Pipeline
      include Enumerable, Xform

      attr_accessor :xforms
      
      def initialize
        @xforms = [ ]
        super
      end

      def size   ; @xforms.size   ; end
      def empty? ; @xforms.empty? ; end
        
      def >> app
        app = app.new.build if app.respond_to?(:new)
        @xforms << app
        self
      end
      alias :| :>>

      def self.>> app
        new >> app
      end
      def self.| app
        new | app
      end
      
      def call table, env
        @xforms.inject(table) do |table, app|
          app.call(table, env)
        end
      end

      def default_io!
        # Default to stdio:
        unless xforms.find{|x| Xform::IoIn === x}
          xforms.unshift(Xform::IoIn.new)
        end
        unless xforms.find{|x| Xform::IoOut === x}
          xforms.push(Xform::IoOut.new)
        end
      end

      def default_format! opts = { }
        if format = opts[:input_format]
          format = format.call if Proc === format
          unless xforms.find{|x| Xform::InputFormat === x}
            ios = [ ]
            while x = xforms.shift
              ios.push x
              break if Xform::IoIn === x
            end
            xforms.unshift(format)
            ios.each{|x| xforms.unshift(x)}
          end
        end

        if format = opts[:output_format]
          format = format.call if Proc === format
          unless xforms.find{|x| Xform::OutputFormat === x}
            ios = [ ]
            while x = xforms.pop
              ios.push x
              break if Xform::IoOut === x
            end
            xforms.push(format)
            ios.each{|x| xforms.push(x)}
            self
          end
        end

        self
      end

      def inspect_content mode
        "[#{@xforms.map(&:inspect) * ' | '}]"
      end
   end
  end
end

