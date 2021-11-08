# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Types < Pipe
  include Pipe::Process, Pipe::NeedsHeader
  def call input, env
    header = input.header
    unless header
      log.warn 'Ignoring request for types: no header present.  Use "// -header" to extract header.'
    else
      header.clear_types!
      input.each do |e|
        puts "  #{self.class} ======================" if debug?
        header.col_types! e
        puts "  ====================================\n\n" if debug?
      end
      header.finalize_types!
    end
    if debug?
      pp(self: self, col_types: Hash[header.map(&:to_sym).zip(header.map(&:type))])
    end
    app.call(input, env)
  end
end

end
