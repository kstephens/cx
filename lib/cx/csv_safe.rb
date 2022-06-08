# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/typing'
require 'csv'

module CX
  # Fall-back for non-compliant CSV formats.
  module CSVSafe
    include Logging
  extend self

  def init_more!
    super
    @encoding ||= "utf-8"
    @csv_parse_options    = { encoding: @encoding, external_encoding: @encoding} # ??? Others
    @csv_generate_options = { encoding: @encoding, quote_empty: false }
    if v = (opts[:separator] || opts[:d])
      case v
      when /^\\x([0-9a-f]+)$/i
        @sep = $1.to_i(16).chr
      when /^\\(0[0-7]+)$/
        @sep = $1.to_i(8).chr
      else
        @sep = v
      end
    end
    @sep_default = @sep || ','
  end
  
  def csv_parse_line line, ri = nil
    row = nil
    begin
      line = remove_BOM(line)
      # HUH??? #<ArgumentError: wrong number of arguments (given 2, expected 1)>
      # ::CSV.parse_line(line, @csv_parse_options)
      if @sep
        row = line.chomp.split(@sep, -1)
      else
        row = ::CSV.parse_line(line)
      end
    rescue ::CSV::MalformedCSVError => exc
      log.warn "CSV parse : fallback : removing \" : #{exc.inspect} : #{ri.inspect} : #{line.inspect}"
      line = line.gsub('"', '')
      begin
        # ::CSV.parse_line(line, @csv_parse_options)
        row = ::CSV.parse_line(line)
      rescue ::CSV::MalformedCSVError
        log.warn "CSV parse : fallback : split on #{@sep_default.inspect} : #{exc.inspect} : #{ri.inspect} : #{line.inspect}"
        row = line.chomp.split(@sep_default, -1)
      end
    end
    row.map!{|s| csv_unescape_value(s)}
  end

  def csv_generate_line row, ri = nil
    begin
      if @sep
        row.join(@sep) << "\n"
      else
        # HUH??? #<ArgumentError: wrong number of arguments (given 2, expected 1)>
        # ::CSV.generate_line(row, @csv_generate_options)
        row_ = row.map{|x| csv_escape_value x}
        ::CSV.generate_line(row_)
      end
    rescue => exc
      raise exc.class, "#{ri.inspect} : #{row.inspect} : #{exc.inspect}", exc.backtrace
    end
  end

  # https://stackoverflow.com/questions/5011504/is-there-a-way-to-remove-the-bom-from-a-utf-8-encoded-file
  # THANKS, EXCEL!
  def remove_BOM line, encoding = nil
    encoding ||= line.encoding
    binary = line.dup.force_encoding("UTF-8")
    binary.gsub!(BOM, '')
    binary
  end
  BOM = "\xEF\xBB\xBF".dup.force_encoding("UTF-8").freeze

  def csv_unescape_value s
    case s
    when String
      s.gsub(/(\\.)/){CSV_UNESCAPE[$1]}
    else
      s
    end
  end
  CSV_UNESCAPE = Hash.new{|h,k| h[k] = (eval("\"#{k}\"") rescue nil) || k}

  def csv_escape_value x
    case x
    when nil
    when String
      x.gsub(/([\r\n\\])/){CSV_ESCAPE[$1] ||= $1}
    else
      Typing.coerce(x, String)
    end
  end
  CSV_ESCAPE = {
    "\\" => "\\\\",
    "\n" => "\\n",
    "\r" => "\\r",
  }
  CSV_ESCAPE_R = CSV_ESCAPE.invert
end
end
