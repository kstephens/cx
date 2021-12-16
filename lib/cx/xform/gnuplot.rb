# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'
require 'cx/xform/csv'
require 'cx/xform/header'
require 'cx/xform/cut'


# :COMMAND:
# GnuplotOut:
#   aliases: [  ]
#   synopsis: Generate GNUPLOT file.
#   suffixes: [ ]
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.csv // -h // jira'

module CX
  module Xform
    class GnuplotOut
      include SelectColumns, OutputFormat, RecordOut
      
      def call input, env
        @env = env
        column_args!(input).or_all!
        xca = column_args.select{|ca| ca.args[0] == 'x'}.first || column_args[0]
        yca = column_args.select{|ca| ca.args[0] == 'y'}.first || column_args[1]
        @x_col = xca ? xca.column : input.header[0]
        @y_col = yca ? yca.column : input.header[1]
        @output = make_output
        header!
        footer!
        data = input
        data = Cut.new.cut(data, env, [ @x_col, @y_col ])
        @x_col, @y_col = data.header.columns
        data = HeaderOut.new.call(data, env)
        data = CsvOut.new.call(data, env)
        data.each {|r| @output << r }
        @env = nil
        @output.tap{|x| @output = nil}
      end

      attr_reader :x_col, :y_col

      def title
        opts[:title] || @env[:title] || @env[:in_file] || ''
      end
      
      def format!
        case fmt = opts[:format] || 'tty'
        when /svg/i
          @output_size ||= [ 1024, 1024 ]
          @output << [ <<"END" ]
            set terminal #{fmt} size #{@output_size * ','}
END
        when /term|tty|console/i
          @output_size ||= stty_size
          @output << [ <<"END" ]
set terminal dumb size #{@output_size * ','}
set autoscale
END
        else
          raise_ "invalid gnuplot format"
        end
      end

      def stty_size
        `stty size`.chomp.split(/\s+/,-1).map(&:to_i).reverse
          .tap { |xy| xy[1] -= 2 } # Adjust for shell prompt!
      end

      def header!
        format!
        @output << [ <<"END" ]
set output  '/dev/stdout'
set title   "#{title}"
set xlabel  "#{x_col}"
set ylabel  "#{y_col}"
set style   data linespoints
set key     autotitle columnhead
set datafile separator ","
plot '/dev/stdin' using 1:2 title "#{title}"
END
      end

      def footer!
        @output << [ <<"END" ]
END
      end
    end
  end
end

