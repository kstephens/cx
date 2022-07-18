# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/xform/record'
require 'cx/xform/stats'
require 'color'

# :COMMAND:
# GnuplotOut:
#   aliases: [ gnuplot ]
#   synopsis: Generate GNUPLOT file.
#   has_column_args: true
#   args: []
#   opts:
#     style=:     'Style of chart.  Values: "plot", "barchart", "statistics".  Default: "plot"'
#     color:      'Generate color plot.  Default: false.'
#     format=:    'Gnuplot format: term,tty,console,svg,...'
#     title=:     'Title.  Default: none.'
#     size=:      'width x height.  Default TTY size or 1024x768.'
#     xrange=:    "min:max.  Default: auto."
#     yrange=:    "min:max.  Default: auto."
#     boxwidth=:  "Default: 0.75."
#     x-labels:   'the X column contains discrete labels.'
#   examples:
#     - 'cx in plot.csv // -h // gnuplot- --size=80x25 // cmd gnuplot'
#     - 'cx in plot.csv // -h // gnuplot- --size=80x25 x // cmd gnuplot'
#     - 'cx in plot.csv // -h // gnuplot- --size=80x25 x y2 // cmd gnuplot'
#     - 'cx in plot.csv // -h // gnuplot- --size=80x25 --style=b x // cmd gnuplot'

module CX
  module Xform
    class GnuplotOut
      include SelectColumns, OutputFormat, RecordOutBase
      
      def call input, env
        @input, @env = input, env
        @popts = opts.dup

        @style = (popts.delete(:style) || "plot")
        case @style
        when /^b/
          @style = :barchart
        when /^c/
          @style = :candlesticks
        when /^f/
          @style = :financebars
        when /^s/
          @style = :statistics
        when /^(p|l)/
          @style = :plot
        else
          raise_ "invalid style : #{@style.inspect}"
        end
        
        @format = popts.delete(:format)
        @title = popts.delete(:title) || @env[:title] || @env[:in_file] || ''
        @size = popts.delete(:size)
        @size &&= @size.split(/\s+|\s*x\s*|\s*,\s*/, 2).map(&:to_i)
        @datafile_separator = popts.delete(:datafile_separator) || "\t"
        @x_labels = popts.delete(:x_labels)
        @color = popts.delete(:color)
        @background_color = popts.delete(:background_color)
        @background_color &&= "background rgb #{@background_color.inspect}"
        @text_color   = popts.delete(:text_color)
        # @title_color = @text_color
        #@text_color &&= "textcolor rgbcolor #{@text_color.inspect}"
        #@title_color &&= "tc rgb #{@title_color.inspect}"
        #@title_color = "tc lt 0"
        
        @output = make_output
        input_columns! input

        plot!
        
        @env = nil
        @output.tap do |x|
          @cols = @input = @output = nil
        end
      end

      attr_accessor :popts
      
      def << line
        @output << [ line.to_s + "\n" ] if line
        self
      end
      
      def input_columns! input
        # Check specified column args:
        column_args!(input).wildcards!
        # If none specified, use header columns:
        # Prefer numeric columns:
        if column_args.empty?
          @cols = column_args.or_all!.args
          numerics = @cols.select{|ca| (ca.column.meta.type_ || ::Object) <= ::Numeric }
          @cols = numerics unless numerics.empty?
        else
          @cols = column_args.args
        end
        
        @cols.each.with_index{|ca, i| ca.opts[:data_index] = i + 2}

        case @cols.size
        when 0
          raise_ "no columns specified"
        when 1 # we only have a y
          @x_col = nil
          @y_cols = @cols
        else
          @x_col  = @cols[0]
          @y_cols = @cols[1 .. -1]
        end

        self
      end
      
      def format!
        case @format
        when nil, /term|tty|console/i
          # set terminal dumb {size <xchars>,<ychars>} {[no]feed}
          #  {aspect <htic>{,<vtic>}}
          #  {[no]enhanced}
          #  {mono|ansi|ansi256|ansirgb}
          @size ||= stty_size
          @xtics = "scale 0.5 nomirror nooffset"
          popts_update(
            terminal:   "dumb size #{@size * ','} aspect 1 noenhanced #{@color ? :ansirgb : :mono}",
            ytics:      "nomirror scale 0.5",
            autoscale:  "",
            # background: 'rgb "black"',' # leads to invisible text.
          )
          @plot_opts = 'pt "@"'
        else
          more = String.new
          case @format
          when /svg/
            more << %Q{ dynamic }
          when /pdf/
            more << %Q{ #{@color && :color} }
          end
          @size ||= [ 1024, 768 ]
          @xtics = "scale 0 nomirror nooffset"
          popts_update(
            terminal:  "#{@format} size #{@size * ','} noenhanced #{more} #{@background_color}",
            ytics:     "scale 0 nomirror",
          )
        end
        self
      end

      def stty_size
        `stty size 2>/dev/null`.chomp.split(/\s+/,-1).map(&:to_i).reverse
          .tap { |xy| xy[1] -= 2 } # Adjust for shell prompt!
      end

      def header!
        popts_update(
          title: @title,
          output: "/dev/stdout",
          border: 0,
          palette: "cubehelix",
          # boxwidth: 0.75,
        )
        popts.delete(:linewidth)
        popts.delete(:whisker)
        
        format!

        popts_update(
          xlabel: @x_col.to_s,
          ylabel: @y_cols == 1 ? @y_cols[0].to_s : "",
        )

        # Reformat:
        # popts[:size]   &&= popts[:size] * ','
        popts[:output] &&= popts[:output].inspect
        popts[:title]  &&= escape_string(popts[:title])
        popts[:xrange] &&= "[#{opts[:xrange]}]"
        popts[:yrange] &&= "[#{opts[:yrange]}]"
        popts[:xlabel] &&= escape_string(popts[:xlabel])
        popts[:ylabel] &&= escape_string(popts[:ylabel])
        
        case @style
        when :barchart, :candlesticks, :financebars, :statistics
          popts[:xrange] ||= "[-0.5:#{@input.size - 0.5}]"
          # popts[:boxwidth] ||= 1.0
          # popts[:bars] ||= 1.5
          # popts[:errorbars] ||= 1.5
        when :plot
          popts_update(
            style: 'data linespoints',
            xtics: @xtics,
          )
        end

        popts.each do | k, v |
          self << (v.nil? ? "unset #{k}" : "set #{k} #{v}")
        end
        # self << %Q{set style fill solid 1.0}
        # self << %Q{set style fill pattern}
        
        self
      end

      def popts_update h = {}
        @popts = h.merge(@popts)
      end
      
      def plot!
        emit_data!

        plots = send(:"plot_#{@style}").flatten
        
        self << %Q{# BEGIN linestypes}
        self << %Q{set linetype 200 linecolor rgb "black"}
        self << %Q{set linetype 201 linecolor rgb "white"}
        self << %Q{set linetype 210 linecolor rgb #{(opts[:background_color] || "black").inspect}}
        self << %Q{set linetype 211 linecolor rgb #{(opts[:text_color]       || "white").inspect}}
        self << %Q{# END   linestypes}
        self << ""

        # Line styles:
        self << %Q{# BEGIN style line}
        y_cols_map do | y_col, i |
          line_style!
        end
        self << %Q{# END   style line}
        self << ""
        
        header!
        self << ''

        self << "plot " + plots * ", \\\n     "
      end
      
      def y_cols_map
        @x_ind = @x_col && data_index(@x_col) + 2
        @y_cols.map.with_index do | y_col, y_i |
          @y_col = y_col
          @y_i = y_i
          @y_ind = data_index(y_col)
          @y_title = escape_string(@y_col)
          yield
        end
      end

      #################################################
      # Styles

      # Iterate over y columns
      def plot_y
        y_cols_map do
          send(:"plot_#{@style}_y")
        end
      end

      alias :plot_plot      :plot_y
      alias :plot_barchart  :plot_y

      def plot_plot_y
        using = case
                when @x_col && opts[:x_labels]
                  "1:#{@y_ind}:xtic(#{@x_ind})"
                when @x_col
                  "#{@x_ind}:#{@y_ind}"
                else
                  "1:#{@y_ind}"
                end
        %Q{#{@datafile.inspect} using #{using} with linespoints linestyle #{@y_i + 100} #{@plot_opts} title #{@y_title} #{@title_color}}
      end

      def plot_barchart_y
        using = case
                when @x_col
                  "1:#{@y_ind}:xtic(#{@x_ind})"
                else
                  "1:#{@y_ind}"
                end
        %Q{#{@datafile.inspect} using #{using} with boxes linestyle #{@y_i + 100} #{@plot_opts} title #{@y_title} #{@title_color}}
      end

      def plot_candlesticks
        # self << "set bars 0.10"
        using = stats_using
        # opts[:linewidth] = 0.5
        # opts[:whisker] = 0.5
        [ %Q{#{@datafile.inspect} using #{using} with candlesticks title "" linewidth #{opts.fetch(:linewidth, 1.5)} whisker #{opts.fetch(:whisker , 0.5)}} ]
      end

      def plot_financebars
        self << "set bars 10.0"
        using = stats_using
        [ %Q{#{@datafile.inspect} using #{using} with financebars title "" linewidth #{opts.fetch(:linewidth, 1.5)}} ]
      end

      def plot_statistics
        using = stats_using
        [
          %Q{#{@datafile.inspect} using #{using} with financebars title "" linewidth #{opts.fetch(:linewidth, 1.5)}},
        ]
      end

      # x,open,low,high,close[,xtic]
      def stats_using
        c = stats_cols
        case
        when ! c[:mean] && ! c[:median]
          c[:mean]   = c[:min]
          c[:median] = c[:max]
        when ! c[:mean] && c[:median]
          c[:mean] = c[:median]
        when ! c[:median] && c[:mean]
          c[:media] = c[:mean]
        end
        using =
           [ 1 ] + 
           [ :mean, :min, :max, :median ].map do |sf| 
              data_index(c[sf] || raise_("no column for stat #{sf.inspect}"))
           end +
           [ '(0.5)' ] # box width.
        using << "xtic(#{data_index(c[:xlabel])})" if c[:xlabel]
        # pp(using: using)
        using * ":"
      end

      def stats_cols
        c = { }
        cols = @cols
        # pp(cols: cols)
        ([ :xlabel ] + Stats::STATS_FIELDS).each do | sf |
          sf_str = sf.to_s
          sf_rx = Regexp.new(sf_str)
          col =
            cols.find{|ca| ca.args[0]          == sf_str } ||
            cols.find{|ca| ca.column.meta.stat == sf_str } ||
            cols.find{|ca| ca.column.to_s      =~ sf_rx }
            c[sf] = col 
        end
        # pp(stats_cols: c)
        c
      end

      def data_index col
        col.opts[:data_index] or raise_ "data_index : #{col.inspect}"
      end

      #################################################
      # Style support

      def line_style!
        self << %Q{set style line #{@y_i + 100} linecolor rgbcolor #{rgb_i(@y_i)}}
      end

      def escape_string s
        # enhanced text mode:
        # s.to_s.gsub('_', '\\\_').inspect
        s.to_s.inspect
      end
      
      def rgb_i i
        palette_frac = i.to_f / @cols.size
        hsvtorgb(palette_frac, 1.0, 0.50)
      end
      
      def hsvtorgb h, s, v
        Color::HSL.new(h * 360.0, s * 100, v * 100).html.inspect
      end

      #################################################
      
      # Emit data block
      def emit_data!
        @datafile = '$data'
        self << ''
        self << '# BEGIN Data'
        self << "set datafile separator #{@datafile_separator.inspect}"
        self << "# #{([:__data_index__]+ @cols.map(&:to_s)) * @datafile_separator}"
        self << "#{@datafile} << EOD"
        index = -1
        @input.each do |r|
          r = @cols.map{|ca| r[ca.column]}
          r.unshift(index += 1)
          self << r * @datafile_separator
        end
        self << 'EOD'
        self << '# END Data'
        self << ''
        self
      end
    end
  end
end
