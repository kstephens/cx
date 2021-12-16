# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'


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
        @columns = column_args!(input).or_all!.columns
        @output = make_output
        header!
        footer!
        # csv = HeaderOut.new.call(input, env)
        csv = CsvOut.new.call(input, env)
        csv.each do | row |
          @output << row
        end
        @env = nil
        @output.tap{|x| @output = nil}
      end

      def x_col
        @columns[0]
      end
      
      def y_col
        @columns[1]
      end

      def output_format
        'svg'
      end

      def format!
        @output_size ||= [ 500, 500 ]
        @output << [ <<"END" ]
          set terminal #{output_format} size #{@output_size * ','}
END
      end

      def output_format
        'terminal dumb'
      end
      
      def format!
        @output_size ||= stty_size
        @output << [ <<"END" ]
set terminal dumb size #{@output_size * ','}
set autoscale
END
      end

      def stty_size
        `stty size`.chomp.split(/\s+/,-1).map(&:to_i).reverse
          .tap { |xy| xy[1] -= 2 } # Adjust for shell prompt!
      end
      
      def header!
        format!
        @output << [ <<"END" ]
set output '/dev/stdout'
set title '#{@env[:title]}'
set xlabel '#{x_col}'
set ylabel '#{y_col}'
set style data lines
#set key autotitle columnhead
#plot for [col=2:3] '/dev/stdin' using 1:col
plot '/dev/stdin' using 1:2
END
      end

      def footer!
        @output << [ <<"END" ]
END
      end
    end
  end
end

