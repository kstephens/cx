# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'
require 'color'

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
        @input, @env = input, env
        @title = opts[:title] || @env[:title] || @env[:in_file] || ''
        @columns = input_columns! input
        @output = make_output

        header!
        plot!
        
        @env = nil
        @output.tap do |x|
          @input = @output = nil
        end
      end

      attr_accessor :data, :columns, :xcol, :ycols, :output
      
      def << line
        @output << [ line.to_s + "\n" ] if line
        self
      end
      
      def input_columns! input
        # Check specified column args:
        column_args!(input)
        columns = column_args.columns
        # If none specified, use header columns:
        # Prefer numeric columns:
        if column_args.columns.empty?
          columns = input.header.columns if columns.empty?
          numerics = columns.select{|c| (c.meta.type_ || ::Object) <= ::Numeric }
          columns = numerics unless numerics.empty?
        end
        case columns.size
        when 0
          raise_ "no columns specified"
        when 1 # we only have a y
          @xcol = nil
          @ycols = columns
        else
          @xcol  = columns[0]
          @ycols = columns[1 .. -1]
        end
        columns
      end
      
      def format!
        @size = opts[:size] and @size = @size.split(/\s+|\s*x\s*|\s*,\s*/, 2).map(&:to_i)
        case fmt = opts[:format]
        when nil, /term|tty|console/i
          # set terminal dumb {size <xchars>,<ychars>} {[no]feed}
          #  {aspect <htic>{,<vtic>}}
          #  {[no]enhanced}
          #  {mono|ansi|ansi256|ansirgb}
          @size ||= stty_size
          @output << [ <<"END" ]
set terminal dumb size #{@size * ','} aspect 1 enhanced #{opts[:color] ? :ansirgb : :mono}
set tics nomirror scale 0.5
set autoscale
END
          @plot_opts = 'pt "@"'
        when /caca/i
          # THIS IS VERY BUGGY:
          # See http://www.gnuplot.info/docs_5.2/Gnuplot_5.2.pdf:
          #set terminal caca {{driver | format} {default | <driver> | list}}
          # {color | monochrome}
          # {{no}inverted}
          # {enhanced | noenhanced}
          # {background <rgb color>}
          # {title "<plot window title>"}
          # {size <width>,<height>}
          # {charset ascii|blocks|unicode}
          @size ||= stty_size
          @output << [ <<"END" ]
# set terminal caca color noinverted background rgb "gray" charset unicode size #{@size * ','}
set terminal caca driver ncurses inverted enhanced background rgb "white" size #{@size * ','}
set autoscale
END
          # @plot_opts = 'pt "#"'
        else
          @size ||= [ 1024, 768 ]
          self << %Q{set terminal #{fmt} size #{@size * ','}}
        end
      end

      def stty_size
        `stty size`.chomp.split(/\s+/,-1).map(&:to_i).reverse
          .tap { |xy| xy[1] -= 2 } # Adjust for shell prompt!
      end

      def header!
        self << <<"END"
set output    "/dev/stdout"
set border    0
set tics      scale 0 nomirror
set style     data linespoints
set title     #{@title.inspect}
set ylabel    #{(ycols.map(&:to_s) * ',').inspect}
set datafile  separator ","
END
        self << %Q{set key     autotitle columnhead} if @data_header

        format!

        x_label = @xcol.to_s if @xcol
        self << %Q{set xlabel    #{x_label.inspect}} if x_label
      end

      def plot_with_for_loop!
        line_styles!
        # ylabel = ycol.to_s
        if @xcol
          range   = "2:#{ycols.size + 1}"
          using   = "1:n"
        else
          range   = "#{ycols.size + 1}"
          using   = "n"
        end
        self << %Q{plot for [n=#{range}] '/dev/stdin' using #{using} w lines linestyle n}
        @columns.each do | c |
          data!
        end
      end
      
      def plot_separate_data_blocks!
        line_styles!
        ycols.each.with_index do | ycol, i |
          self << %Q{plot #{plot_y('-', ycol, i)}}
          data_ycol! ycol
        end
      end

      alias :plot! :plot_separate_data_blocks!
      
      def plot_y datafile, ycol, i
        i += 2
        using = @xcol ? "1:2" : "1"
        %Q{#{datafile.inspect} using #{using} #{@plot_opts} with lines linestyle #{i} title #{ycol.to_s.inspect}}
      end

      def line_styles!
        ycols.each.with_index do| ycol, i |
          palette_frac = i.to_f / ycols.size
          rgb = hsvtorgb(palette_frac * 360, 100.0, 50.0)
          self << %Q{set style line #{i + 2} lc rgb #{rgb.inspect}}
        end
      end
      
      def hsvtorgb h, s, v
        Color::HSL.new(h, s, v).html
      end

      def data!
        @input.each do |r|
          r = @columns.map{|c| r[c]}
          self << r * ','
        end
        self << "e"
      end
      
      def data_ycol! ycol
        if @data_header
          xcol = @xcol && @xco.to_s + ','
          str = "#{xcol}#{ycol}"
          self << str
        end
        
        @input.each do |r|
          xcol = @xcol && r[@xcol].to_s + ','
          str = "#{xcol}#{r[ycol]}"
          self << str
        end
        self << "e"
        self << ""
      end
    end
  end
end
