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

      def inspect_content mode
        "[#{@xforms.map(&:inspect) * ' | '}]"
      end
   end
  end
end

