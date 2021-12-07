# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Tee < Pipe
  attr_reader :outputs
  def init_more!
    super
    @outputs = args
    @outputs.each do | o |
      raise_ "expected pipeline argument: #{o.inspect}" unless Pipe::Pipeline === o
    end
    # pp(outputs: outputs)
  end
  def call input, env
    outputs.each do | output |
      # Pipelines often edit tables in-place.
      # Input must be deep copied for each output.
      output.call(input.dup_deep, env)
    end
    app.call(input, env)
  end
end

end
