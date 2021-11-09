# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
    class Pipeline
      include Xform

      attr_accessor :apps
      
      def initialize!
        @apps = [ ]
        super
      end

      def >> app
        app = app.new if app.respond_to?(:new)
        @apps << app
        self
      end

      def call table, env
        @apps.inject(table) do |table, app|
          app.call(table, env)
        end
      end

      def inspect_content
        " (#{@apps.map(&:inspect) * ' >> '})"
    end
   end
  end
end

