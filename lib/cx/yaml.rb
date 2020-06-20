# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/structured'
require 'yaml'

module CX
  class YamlIn < StructuredIn
    include Pipe::Parse
    def parse input, env
      YAML.load(input)
    end
  end
  
  class YamlOut < Pipe
    def content_type ; 'application/json' ; end
    def call input, env
      env[:content_type] = 'application/yaml'
      app.call([YAML.dump(input.as_hash_array)], env)
    end
  end
end
