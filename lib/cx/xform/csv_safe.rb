# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'
require 'csv'

module CX
  module Xform
    # Handle non-compliant CSV formats.
    class CSVSafe
      attr_accessor :opts, :encoding, :parse_options, :generate_options
      def initialize opts
        @opts = opts
        @encoding ||= "utf-8"
        @parse_options    = { encoding: @encoding, external_encoding: @encoding} # ??? Others
        @generate_options = { encoding: @encoding, quote_empty: false }
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
      end

      def parse_line line, ri = nil
        row = nil
        begin
          line = remove_BOM(line)
          # HUH??? #<ArgumentError: wrong number of arguments (given 2, expected 1)>
          # ::CSV.parse_line(line, @parse_options)
          if @sep
            row = line.chomp.split(@sep, 9999)
          else
            row = ::CSV.parse_line(line)
          end 
        rescue ::CSV::MalformedCSVError => exc
          $stderr.puts "  # cx : WARN: Removing \" : #{exc.inspect} : #{ri.inspect} : #{line.inspect}"
          line = line.gsub('"', '')
          begin
            # ::CSV.parse_line(line, @parse_options)
            row = ::CSV.parse_line(line)
          rescue ::CSV::MalformedCSVError
            $stderr.puts "  # cx : WARN: Falling back to split on \",\" : #{exc.inspect} : #{ri.inspect} : #{line.inspect}"
            row = line.split(',', -1)
          end
        end
        row ? row.map!{|s| unescape_value(s)} : [ ]
      end

      def generate_line row, ri = nil
        begin
          if @sep
            row.join(@sep) << "\n"
          else
            # HUH??? #<ArgumentError: wrong number of arguments (given 2, expected 1)>
            # ::CSV.generate_line(row, @generate_options)
            row_ = row.map{|x| escape_value x}
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

      def unescape_value s
        case s
        when String
          # TODO: handle other escape sequences: octal, unicode
          s.gsub(/(\\.)/){UNESCAPE[$1]}
        else
          s
        end
      end
      UNESCAPE = Hash.new{|h,k| h[k] = (eval("\"#{k}\"") rescue nil) || k}

      def escape_value x
        case x
        when nil
        when String
          x.gsub(/([\r\n\\])/){ESCAPE[$1] ||= $1}
        else
          Typing.coerce(x, String)
        end
      end
      ESCAPE = {
        "\\" => "\\\\",
        "\n" => "\\n",
        "\r" => "\\r",
      }
      ESCAPE_R = ESCAPE.invert
    end
  end
end
