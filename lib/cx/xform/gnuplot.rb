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
          self << <<"END"
set terminal dumb size #{@size * ','} aspect 1 enhanced #{opts[:color] ? :ansirgb : :mono}
set tics nomirror scale 0.5
set autoscale
END
          @plot_opts = 'pt "@"'
        else
          @size ||= [ 1024, 768 ]
          self << %Q{set terminal #{fmt} size #{@size * ','}}
          #  background rgb "black" leads to invisible text.
        end
      end

      def stty_size
        `stty size`.chomp.split(/\s+/,-1).map(&:to_i).reverse
          .tap { |xy| xy[1] -= 2 } # Adjust for shell prompt!
      end

      def header!
        format!

        self << <<"END"
set output "/dev/stdout"
set border 0
set tics scale 0 nomirror
set style data linespoints
set title  #{@title.inspect}
set ylabel #{(ycols.map(&:to_s) * ',').inspect}
END
        self << %Q{set key autotitle columnhead} if @data_header

        x_label = @xcol.to_s if @xcol
        self << %Q{set xlabel #{x_label.inspect}} if x_label
      end

      def plot_separate_data_blocks!
        ycols.each.with_index do | ycol, i |
          line_style! ycol, i
        end
        
        self << ''
        self << 'set datafile separator ","'
        self << "$data << EOD"
        data!
        self << 'EOD'
        self << ''
        
        plots = ycols.map.with_index do | ycol, i |
          plot_y("$data", ycol, i)
        end
        self << "plot " + plots * ', '
      end

      alias :plot! :plot_separate_data_blocks!
      
      def plot_y datafile, ycol, i
        ind = ycol.to_i + 1
        using = @xcol ? "1:#{ind}" : "#{ind}"
        %Q{#{datafile.inspect} using #{using} with linespoints linestyle #{i + 2} #{@plot_opts} title #{ycol.to_s.inspect}}
      end

      def line_style! ycol, i
        i += 2
        self << %Q{set style line #{i + 2} linecolor rgbcolor #{rgb_i(i)}}
      end

      def rgb_i i
        palette_frac = i.to_f / ycols.size
        # "hsv2rgb(#{palette_frac}, 1.0, 0.85)"
        hsvtorgb(palette_frac, 1.0, 0.85)
      end
      
      def hsvtorgb h, s, v
        Color::HSL.new(h * 360.0, s, v).html.inspect
      end

      def data!
        @input.each do |r|
          r = @columns.map{|c| r[c]}
          self << r * ','
        end
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
      end
    end
  end
end
