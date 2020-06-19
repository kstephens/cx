# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'csv'

module CX
  # Fall-back for non-compliant CSV formats.
module CSVSafe
  extend self

  def init_more!
    super
    @encoding ||= "utf-8"
    @csv_parse_options    = { encoding: @encoding, external_encoding: @encoding} # ??? Others
    @csv_generate_options = { encoding: @encoding, quote_empty: false }
  end
  
  def csv_parse_line line, ri = nil
    row = nil
    begin
      # line = remove_BOM(line)
      # HUH??? #<ArgumentError: wrong number of arguments (given 2, expected 1)>
      # ::CSV.parse_line(line, @csv_parse_options)
      row = ::CSV.parse_line(line)
    rescue ::CSV::MalformedCSVError => exc
      $stderr.puts "  # cx : WARN: Removing \" : #{exc.inspect} : #{ri.inspect} : #{line.inspect}"
      line = line.gsub('"', '')
      begin
        # ::CSV.parse_line(line, @csv_parse_options)
        row = ::CSV.parse_line(line)
      rescue ::CSV::MalformedCSVError
        $stderr.puts "  # cx : WARN: Falling back to split on \",\" : #{exc.inspect} : #{ri.inspect} : #{line.inspect}"
        row = line.split(',', -1)
      end
    end
    row.map!{|s| csv_unescape_value(s)}
  end

  def csv_generate_line row, ri = nil
    begin
      # HUH??? #<ArgumentError: wrong number of arguments (given 2, expected 1)>
      # ::CSV.generate_line(row, @csv_generate_options)
      row_ = row.map{|s| csv_escape_value s}
      ::CSV.generate_line(row_)
    rescue => exc
      raise exc.class, "#{ri.inspect} : #{row.inspect} : #{exc.inspect}", exc.backtrace
    end
  end

  def remove_BOM line, encoding = nil
    encoding ||= line.encoding
    binary = line.dup.force_encoding("binary")
    if binary.gsub!("\xEF\xBB\xBF", '')
      line = binary.force_encoding(encoding, :invalid => :replace, :undef => :replace, :replace => "")
    end
    line
  end

  def csv_unescape_value s
    case s
    when String
      s.gsub(/(\\.)/){CSV_UNESCAPE[$1]}
    else
      s
    end
  end
  CSV_UNESCAPE = Hash.new{|h,k| h[k] = (eval("\"#{k}\"") rescue nil) || k}

  def csv_escape_value s
    case s
    when String
      s.gsub(/([\r\n\\])/){CSV_ESCAPE[$1] ||= $1}
    else
      s
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
