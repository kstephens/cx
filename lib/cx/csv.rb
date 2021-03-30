# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/pipe'
require 'cx/csv_safe'

module CX
  class CsvIn < Pipe
    include Pipe::Parse
    include CSVSafe
    # TODO: Potentially refactor into a IOLines base class.
    def call input, env
      i = 0
      input.map! do |e|
        i += 1
        e = e.strip
        csv_parse_line(e, i) unless e.empty?
      end.compact!
      app.call(input, env)
    end
  end

  class CsvOut < Pipe
    include CSVSafe, Pipe::Format
    # TODO: Potentially refactor into a IOLines base class.
    def call input, env
      i = -1
      input.map!{ |e| csv_generate_line(e, (i += 1)) }
      env[:content_type] = 'application/csv'
      app.call(input, env)
    end
  end
end
