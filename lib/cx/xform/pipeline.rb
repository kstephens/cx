# frozen_string_literal: true

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class Pipeline
      include Xform

      attr_accessor :apps
      
      def initialize
        @apps = [ ]
        super
      end

      def >> app
        app = app.new.build if app.respond_to?(:new)
        @apps << app
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
        @apps.inject(table) do |table, app|
          app.call(table, env)
        end
      end

      def inspect_content mode
        "[#{@apps.map(&:inspect) * ' | '}]"
      end
   end
  end
end

