# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'
require 'cx/xform/csv'
require 'cx/xform/header'
require 'cx/xform/cut'


# :COMMAND:
# GnuplotOut:
#   aliases: [ gnuplot ]
#   synopsis: Generate GNUPLOT file.
#   opts: {}
#   examples:
#     - 'cx in plot.csv // -h // gnuplot- --size=80x25 // cmd gnuplot'

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
        @size = opts[:size] and @size = @size.split(/\s+|\s*x\s*|\s*,\s*/, 2).map(&:to_i)
        case fmt = opts[:format]
        when nil, /term|tty|console/i
          @size ||= stty_size
          @output << [ <<"END" ]
set terminal dumb size #{@size * ','}
set autoscale
END
        else
          @size ||= [ 1024, 1024 ]
          @output << [ <<"END" ]
            set terminal #{fmt} size #{@size * ','}
END
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

