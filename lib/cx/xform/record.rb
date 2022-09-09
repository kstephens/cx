# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/meta'

# :COMMAND:
# RecordIn:
#   aliases: [ -record ]
#   synopsis: 'Parses records.'
#   suffixes: [ ]
#   inverse: [ 'record-' ]
#   arguments: []
#   options:
#     record-sep=:  'Record separator.  Default: platform newline.'
#     field-sep=:   'Field separator.   Default: "".'

# :COMMAND:
# RecordOut:
#   aliases: [ record- ]
#   synopsis: 'Generates records.'
#   suffixes: [ ]
#   inverse: [ '-record' ]
#   arguments: []
#   options:
#     record-sep=:  'Record separator.  Default: platform newline.'
#     field-sep=:   'Field separator.   Default: "".'
#     record-cont-sep=:   'Record continuation separator.'

module CX
  module Xform
    module RecordBaseInit
      def initialize!
        super
        @record_sep  , @record_sep_rx   = decode_sep(opts.fetch(:record_sep,  @record_sep_default  ||= $/ ))
        @field_sep   , @field_sep_rx    = decode_sep(opts.fetch(:field_sep,   @field_sep_default   ||= ","))
        @multi_sep   , @multi_sep_rx    = decode_sep(opts.fetch(:multi_sep,   @multi_sep_default   ||= ";"))
        @record_cont_sep  , @record_cont_sep_rx   = decode_sep(opts.fetch(:record_cont_sep,  @record_cont_sep_default  ||= nil))
        @field_cont_sep   , @field_cont_sep_rx    = decode_sep(opts.fetch(:field_cont_sep,   @field_cont_sep_default   ||= nil))
      end
  
      def decode_sep s
        case s
        when nil
          [ '', nil ]
        when %r{\A/(.+)/\Z}
          [ s, Regexp.new($1, Regexp::MULTILINE) ]
        else
          [ s, Regexp.new(Regexp.quote(s), Regexp::MULTILINE) ]
        end
      end
    end

    module RecordBase
      include RecordBaseInit, Xform
      attr_accessor :col_sep, :row_sep, :multi_sep
    
      def make_record_table cols = []
        cols = cols.map{|c| Column.new(c).tap{|c| c.meta.type = ::String}}
        Table.new([], Header.new(cols))
      end
    end

    module RecordInBase
      include RecordBaseInit, InputFormat, RecordBase
      
      def call input, env
        raise_ ArgumentError, "expected one input row, has #{input.size}" unless input.size == 1
        raise_ ArgumentError, "expected one input col, has #{input.first.size}" unless input.first.size == 1
        input_string = input[0][0].to_s
        input_string.gsub!(@record_cont_sep_rx, '') if @record_cont_sep_rx
        rows = input_string.split(@record_sep_rx, -1)
        input_string = nil # GC
        rows.pop if rows[-1].empty? # "ROW\n".split(/\n/, -1) => ["ROW", ""]
        call_with_rows input, env, rows 
      end

      def call_with_rows input, env, rows
        rows.map!{|line| parse_record(line)}
        width = rows.map(&:size).max
        header = Header.new(width || 0).each{|c| c.meta.type = ::String}
        output = Table.new(rows, header)
        output = MetaIn.new.call(output, env)
        output
      end

      def parse_record line
        raise Exception, line
      end
    end
    
    module RecordOutBase
      include OutputFormat, RecordBase
      
      def make_output
        make_record_table([:_RECORD_])
      end

      def format_value v
        case v
        when nil
          nil
        when Enumerable
          v.map{|e| format_value(e).to_s} * multi_sep
        else
          v.to_s
        end
      end
    end

    ###########################

    class RecordIn
      include RecordInBase
      def parse_record line
        if @field_sep.empty?
          [ line ]
        else
          line.split(@field_sep_rx, -1)
          # TODO: handle multi values
        end
      end
    end

    class RecordOut
      include SelectColumns, RecordOutBase
      def call input, env
        cols = column_args!(input).or_all!.columns.sort_by(&:order)
        out = String.new
        input.each do | r |
          out << cols.map do | c |
            r._get(c).to_s # TODO: handle multi values
          end.join(@field_sep)
          out << @record_sep
        end
        output << [ out ]
        output
      end
    end
  end
end

