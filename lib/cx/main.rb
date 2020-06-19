#!/usr/bin/env ruby
# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8

# cx: Copyright 2020, Kurt Stephens

# "cx --help" for documentation.
# "cx ---test---" to execute tests.

require 'cx'
require 'cx/logging'
require 'cx/util'
require 'cx/csv_safe'
require 'cx/pipe'
require 'cx/io'
require 'set'
require 'shellwords'
require 'tempfile'
require 'cgi/util'
require 'thread'
require 'pp'

######################################

module CX
# Main command line driver.
class Main
  include Logging
  extend Logging
  attr_accessor :progname, :args, :opts, :env, :pipeline, :exit_code
  
  def initialize args
    @progname = File.basename($0)
    @args = args.map(&:dup)
    @exit_code = 0
    @opts = { }
    @env = { }
    @verbose = false
  end

  def run!
    log.level = Logger::WARN
    @env = {
      main: {
        progname: $0,
        ARGV: args,
        # ENV: ENV,
        t0: Time.now,
      }
    }
    
    args = self.args.map(&:dup)
    @env_opts = Shellwords.shellsplit(ENV['CX_OPTS'] || '')
    args = @env_opts + args
    @opts = parse_opts! args
    env[:opts] = opts
    
    @verbose = opts[:verbose]
    @debug = @opts[:debug]
    CX::Logging.debug = @debug
    log.level = Logger::INFO  if @verbose
    log.level = Logger::DEBUG if @debug
    
    case
    when opts[:help]
      help!
      exit 0
    when opts[:_test___]
      test!
    when opts[:_pry___]
      if opts[:_break___]
        binding.pry
        :stopped_here
      end
    end

    @pipeline = parse_pipeline! args
    env[:main][:commands] = @pipeline

    pp(pipeline: @pipeline) if @debug
    @app = make_pipeline @pipeline

    go!

    self
  rescue => exc
    log.error "#{progname} : #{exc.inspect}"
    log.info { (["backtrace:::"] + exc.backtrace.reverse + [":::"]).join("\n") }
    @exit_code = 1
    self
  ensure
    GC.start(full_mark: true, immediate_sweep: true)
  end

  # Starts application command pipeline.
  def go!
    @app.run! env
    self
  end

  # TODO: use an option parse library?
  def parse_opts! args
    opts = { }
    while arg = args.first
      case arg
      when /^--([^=]+)=(.*)$/
        k, v = $1, $2
      when /^--([^=]+)$/
        k, v = $1, 1
      when /^\+\+([^=]+)$/
        k, v = $1, -1
      when '--'
        args.shift
        break
      else
        break 
      end
      k = k.gsub('-', '_').to_sym
      if Numeric === v
        x = (opts[k] || 0) + v
        v = false if v <= 0
      end
      opts[k] = v
      args.shift
    end
    opts
  end

  ###################################
  # Parse pipeline
  #
  
  def parse_pipeline! args
    pipeline = [ ]
    pp(parse_pipeline!: args) if @debug
    while arg = args.shift
      case arg
      when '//'
      else
        args.unshift arg
        pipeline << parse_cmd!(args)
      end
    end
    raise_ "empty pipeline #{self.args.inspect}" if pipeline.empty?
    pipeline.extend(Pipe::Pipeline)
    # pp(pipeline: pipeline)
    pipeline
  end

  def parse_cmd! args
    name = args.shift.to_sym
    opts = parse_opts! args
    cmd = [ name, cmd_args = [ ], opts ]
    while arg = args.shift
      case arg
      when '//'
        break
      when '{{'
        cmd_args << parse_pipeline!(args)
      when '}}'
        args.unshift nil # sentinel for parse_pipeline!
        break
      else
        cmd_args << arg
      end
    end
    cmd
  end

  ###################################
  # Build pipeline
  #
  
  # Applications are right folded.
  # If input/output applications are unspecified,
  # STDIN and STDOUT are wrapped the pipeline.
  def make_pipeline pipeline
    unless Pipe.factory(pipeline[0][0])  <= Pipe::In
      pipeline.unshift([:in, [$stdin]])
    end
    unless Pipe.factory(pipeline[-1][0]) <= Pipe::Out
      pipeline.push([:out, [$stdout]])
    end
    pp(pipeline: pipeline) if @debug
    app = reduce_pipeline app, pipeline
    app
  end

  def reduce_pipeline app, pipeline
    pipeline.reverse.inject(app) do |app, spec|
      make_cmd app, spec
    end.extend(Pipe::Pipeline)
  end
  
  def make_cmd app, cmd
    name, args, opts = cmd
    pp(make_cmd: [app, cmd]) if @debug    
    args.map! do |arg|
      Pipe::Pipeline === arg ? reduce_pipeline(nil, arg) : arg
    end
    new_app = Pipe.factory(name).new(app, args, opts)
    new_app = HeaderIn.new(new_app) if Pipe::NeedsHeader === new_app
    new_app = Debug.new(new_app) if @debug
    new_app
  end

  def test!
    require 'cx/help_and_test'
    unit_test!
    CX::HelpAndTest.test!(opts)
    exit 0
  end
  
  def unit_test!
    [
      # {"" => []},
      {"in" =>
       [[:in, [], {}]]},
      {"in foo" =>
       [[:in, ["foo"], {}]]},
      {"in --a=1 --b baz" =>
       [[:in, ["baz"], {a: "1", b: 1}]]},
      {"in --a=1 foo // out bar" =>
       [[:in,  ["foo"], {a: "1"}],
        [:out, ["bar"], {}]]},
      {"in foo {{ a // b }}" =>
       [[:in, ["foo", [
                 [:a, [], {}],
                 [:b, [], {}]]
              ], {}]]},
      {"in --a foo {{ a --b=2 // b --c }} // out bar" =>
       [[:in, ["foo", [
                 [:a, [], {b: "2"}],
                 [:b, [], {c: 1}]]],
         {a: 1}],
        [:out, ["bar"], {}]]},
    ].each do | x |
      cmd_line, expected = x.keys.first, x.values.first
      cmd_args = Shellwords.split(cmd_line)
      # pp(cmd_line: cmd_line, cmd_args: cmd_args); binding.pry
      actual = parse_pipeline! cmd_args
      assert_eq! expected, actual        , cmd_line
      assert_eq! 0,        cmd_args.size , cmd_line
    end
    
    result = make_cmd :app, [:in, ["arg1"], {opt: "opt"}]
    assert_eq!(IOIn,          result.class)
    assert_eq!(:app,          result.app)
    assert_eq!(["arg1"],      result.args)
    assert_eq!({opt: "opt"},  result.opts)

    self
  end

  def assert_eq! expected, actual, msg = nil
    line = caller[0].sub(/:in.*/, '')
    result = expected == actual
    
    msg = <<"END"
#{msg} :
  expected: #{expected.inspect}
  actual:   #{actual.inspect}
  line:     #{line}"
END
    msg = (result ? "OK:    " : "FAIL: ") + msg
    if ! result && opts[:break]
      puts msg + "\n"
      binding.pry
    end
    raise_ msg unless result
    puts   msg
    result
  end

  def inspect
    "#<#{self.class} #{args.inspect}>"
  end
  
  def help!
    require 'cx/help_and_test'
    cmds = Pipe::COMMANDS.values
    cls_section = {
      IOPipe => "I/O",
      Pipe::Parse => "Parsing",
      Pipe::Format => "Format",
      Pipe::Process => "Processing",
      Pipe::Diagnostic => "Diagnostic",
      Object => "Other",
    }
    cmd_order = cls_section.keys
    cmds.each{|cmd| cmd[:type] = Typing.first_superclass(cmd_order, cmd[:class])[0]}
    cmd_metric = lambda{|cmd| Typing.first_superclass(cmd_order, cmd[:class])[1]}
    cmd_cmp = lambda {|a, b| (cmd_metric[a] <=> cmd_metric[b]).nonzero? || a[:name] <=> b[:name] }
    cmd_cmp_ = cmd_cmp
    
    cmds.sort!(&cmd_cmp)

    w = cmds.map{|c| c[:name].to_s.size}.max + 1
    cmds.each do |c|
      syn = c[:synopsis].split(/   |\n/, -1).map(&:strip)
      aliases = c[:aliases].empty? ? "" : "aka: #{c[:aliases].map(&:to_s).map(&:inspect) * ', '}"
      rest = [ *syn[1..-1], aliases ].reject(&:empty?)
      c[:doc] =
        (
          [ "%-#{w}s - %s" % [c[:name].to_s, syn[0]] ] +
          rest.map{|s| "%#{w}s     %s" % ["", s]}
        ) * "\n"
      c[:section] = cls_section[c[:type]]
    end
    sections = cmds.group_by{|cmd| cmd[:section]}
    cmd_doc = sections.map do |sec, cmds|
      "\n     #{sec}:\n\n#{cmds.map{|c| c[:doc]} * "\n"}"
    end * "\n"
    
    help = <<"END"
#{progname} : Manipulate CSVs and other tablular data.

  COMMANDS:
  --------
#{cmd_doc}

  EXAMPLES:
  --------

#{::HelpExamplesAndTest.examples.sub(/\n+\Z/, '')}

  ATTRIBUTION:
  -----------

Copyright 2020, Kurt Stephens, https://github.com/kstephens

END
    puts help
  end
  
end

######################################

################################

class Debug < Pipe
  include Pipe::Diagnostic
  register! :debug,
            'emits debug information during processing   If --table, dump input/output tables.'
  def call input, env
    app.reraise do
      dump!("<<< input", input, env)
      @@indent += 2
      output = app.call(input, env)
      @@indent -= 2
      dump!(">>> output", output, env)
      output
    end
  end

  def dump! ident, table, env
    o = String.new
    o << "\n" <<
      ident << "\n" <<
      ppss(app: app) << "\n" <<
      ppss(table: table) << "\n"
    table && table.each{|e| o << ppss(e) << "\n"} if opts[:table]
    o.gsub!("\n", "\n" + " " * @@indent)
    $stderr.puts o
  end
  @@indent = 0
end

################################

## ??? NEEDS TEST
class Grep < Pipe
  include Pipe::Process
  register! :grep,
            'emit rows matching specified column regexs'
  # TODO: support regex negation: e.g. "grep cola:v some.*thing colb other."
  def call input, env
    cols = []; rxs = []; a = args.dup;
    until a.empty? ; cols << a.shift; rxs << a.shift; end
    cols = input.header!.col(cols)
    rxs.map!{|s| Regexp.new(s)}
    row_fn = input.header.row_fn(cols)
    input.select! do | r |
      r = row_fn.call(r)
      r.zip(rxs).all?{|(v,rx)| rx.match?(v.to_s)}
    end
    app.call(input, env)
  end
end

class Transpose < Pipe
  include Pipe::Process
  register! [ :transpose, :xpose ],
            'transpose table'
  def call input, env
    if input.header
      input.unshift input.header.map(&:to_s)
    end
    width, height = (input[0] || []).size, input.size
    output = new_table(Table)
    output.rows = (0 ... width).map{|_| [nil] * height}
    input.each_with_index do | row, row_i |
      row.each_with_index do | val, col_i |
        output[col_i][row_i] = val
      end
    end
    app.call(output, env)
  end
end

class Region < Pipe
  include Pipe::Process
  register! [ :range, :region ],
            'emit regions of rows   E.g: "1" for first row, "-2" 2nd from last, "2..10".'
  def call input, env
    regions = args.flat_map do|arg|
      arg.strip.split(/\s+|\s*,\s*/)
    end.map{|arg| parse_region(input, arg)}
    
    output = new_table(input)
    regions.each do | (a, b, exc) |
      rows = a <= b ?
               input[Range.new(a, b, exc)] :
               input[Range.new(b, a, exc)].reverse!  
      output.concat(rows)
    end
    app.call(output, env)
  end

  def parse_region input, arg
    case arg
    when /^([-+]?\d+)$/
      arg = arg.to_i - 1
      arg = input.size + arg + 1 if arg < 0
      [ arg, arg, false ]
    when /^([^.]+)\.\.(\.)?([^.]+)$/
      a, exc, b = parse_region(input, $1), $2, parse_region(input, $3)
      a = a.first; b = b.first
      [ a, b, ! ! exc ]
    else
      raise_ "Invalid range #{arg.inspect}"
    end
  end
end

class Cut < Pipe
  include Pipe::Process, Pipe::ColumnsFromArgs
  include Pipe::NeedsHeader
  register! :cut,
            'emit specified columns   "@" represents all columns, columns can be reordered: "b,@", or deleted: "@,b-".'
  def call input, env
    header = input.header!
    columns = self.columns || [ ]
    pp(columns: columns) if debug?
    cols = [ ]
    columns.each do | (col, opts) |
      case col
      when "*", "@"
        cols.concat(header.cols).uniq!
      else
        if opts[:-]
          hc = header.col(col)
          cols = cols.reverse.select do |c|
            c == hc ? hc = nil : c 
          end.reverse.compact
        else
          hc = header.col(col)
          cols.delete(hc)
          cols << hc
        end
      end
    end
    pp(cols: cols) if debug?
    row_fn = header.row_fn(cols)
    input.map!(&row_fn)
    input.header = Header.new(cols.map(&:dup_deep))
    app.call(input, env)
  end
end

# Sort rows.
# Specific columns can be specified.
class Sort < Pipe
  include Pipe::Process, ColumnsFromArgs
  include Pipe::NeedsHeader
  register! :sort,
            'sort by specified columns   Columns specified with ":-" option will sort in reverse.'
  def call input, env
    header = input.header!
    sort_cols =
      if (columns || []).empty?
        # Use all columns, without any opts.
        header.map{|c| [c, opts]}
      else
        # Lookup columns, keep opts
        columns.map{|(n,o)| [ header.col(n), o ]}
      end
    pp(sort_cols: sort_cols) if debug?

    # Indexes into row sort values.
    sort_inds = sort_cols.map(&:first).map(&:to_i)
    # Column types for each sort value.
    col_types = sort_inds.map(&header).map(&:type)
    # Change sign of comparison for each sort value.
    cmp_dir   = sort_cols.map{|c,opts| opts[:-] || opts[:r] || opts[:reverse] ? -1 : 1}
    pp(col_types: col_types) if debug?

    # Construct [ sort_values, row ].
    rs = input.map do |r|
      vals = r.values_at(*sort_inds)
      i = -1; vals.map! do | v |
        i += 1
        Typing.coerce(vals[i], col_types[i])
      end
      [ r, vals ]
    end
    pp(rs: rs) if debug?

    # Compare each sort_value in specified column order.
    sort_key_fn = lambda do | a , b |
      a = a[1]; b = b[1]; c = 0
      col_types.each_with_index do | t, i |
        if c = Typing.compare(t, a[i], b[i]) * cmp_dir[i] and ! c.zero?
          break
        end
      end
      c
    end
    
    rs.sort!(&sort_key_fn)
    pp(rs_sorted: rs) if debug?

    input.rows = rs.map!(&:first)
    rs = nil # GC
    app.call(input, env)
  end
end

class Uniq < Pipe
  include Pipe::Process, Pipe::ColumnsFromArgs
  register! :uniq,
            'emit unique rows   Specified rows delimit uniqness.'
  def call input, env
    if header = input.header
      cols = (columns || []).empty? ? header.cols : header.col(columns.map(&:first))
      row_fn = header.row_fn(cols)
    else
      row_fn = Proc.new{|x| x}
    end
    seen = Set.new
    input.select! do | e |
      e = row_fn.call(e)
      seen << e unless seen.include?(e)
    end
    row_fn = seen = nil # GC
    app.call(input, env)
  end
end

class Eval < Pipe
  include Pipe::Process
  register! :eval,
            'evaluate Ruby expression for each row   Assignments to "self" (or "_") update values.  Assignments to non-existant header columns results in new columns.'
  def call input, env
    fn = "Proc.new do \n " + args.join(" ;\n") + "\nend\n"
    fn = eval(fn)
    ec = RowContext.new
    ec.input = input
    ec.env = env
    ec.header = input.header!
    input.select! do | r |
      catch(:skip!) do
        ec.row = r
        ec.instance_eval(&fn)
        :keep!
      end # throw is false
    end
    app.call(input, env)
  end
  
  class RowContext < BasicObject
    attr_accessor :row, :input, :env, :header
    def _ ; self ; end # Shorthand

    def __col name
      unless col = @header[name]
        col = @header.add_col!(name)
      end
      col
    end
    def __col_fn sel
      case
      when @row.respond_to?(sel)
        lambda do |*args, &blk|
          @row.send(sel, *args, &blk)
        end
      when /^(\w+)$/.match(sel.to_s)
        col_i = __col($1).to_i
        ::Kernel.lambda do ||
          @row[col_i]
        end
      when /^(\w+)=$/.match(sel.to_s)
        col = __col($1); col_i = col.to_i
        ::Kernel.lambda do |v|
          col.col_type!(v)
          @row[col_i] = v
        end
      else
        ::Proc.new do | *args, &blk |
          raise "Undefined method #{sel} in row #{@row.inspect}"
        end
      end
    end

    def next!
      ::Kernel.throw(:skip!, false)
    end

    def method_missing sel, *args, &blk
      sel = sel.to_sym
      fn = __col_fn(sel)
      _define_singleton_method(sel, &fn)
      fn.call(*args, &blk)
    end
    
    define_method(:_define_singleton_method, ::Object.instance_method(:define_singleton_method))
  end
end

############################################

class HeaderIn < Pipe
  include Pipe::Parse, Pipe::ColumnsFromArgs
  register! [ :'-h', :"-header" ],
  'capture column header from first row   Typically used after "-csv".'
  def call input, env
    case
    when columns && ! columns.empty?
      input.header = Header.new(columns)
    when ! input.header
      row = input.shift
      row = row.keys if Hash === row
      input.header = Header.new(row)
    end
    app.call(input, env)
  end
end

class HeaderOut < Pipe
  include Pipe::Format
  register! [ :'h-', :"header-" ],
  'emit column names in first row   Typically used before "csv-".'
  def call input, env
    if input.header
      input.unshift input.header.map(&:to_s)
    end
    app.call(input, env)
  end
end

class DefineColumns < Pipe
  include Pipe::Diagnostic, Pipe::NeedsHeader
  register! [ :"columns", :"cols=" ],
  'Define columns   Specify/override column names and options.'
  def call input, env
    col_opts = Header.parse_column_args(args)
    header = input.header ||= Header.new
    col_opts.each do | (name, opts) |
      col = header[name] || header.add_col!(name)
      col.opts = opts
    end
    app.call(input, env)
  end
end

class ColumnsOut < Pipe
  include Pipe::Diagnostic, Pipe::NeedsHeader
  register! [ :"columns-", :"cols-" ],
  'emit header column attributes'
  def call input, env
    cols = [:name, :ind, :type, :min_width, :max_width, :justify]
    header = Header.new(cols)
    output = new_table(Table, header)
    output.rows = input.header.map do | c |
      cols.map{|sel| c.send(sel)}
    end
    Types.new(app, [], {}).call(output, env)
  end
end

############################################

class Types < Pipe
  include Pipe::Process, Pipe::NeedsHeader
  register! :types,
            'infer column types from values   Empty strings or nil values are considered inconclusive.'
  def call input, env
    header = input.header
    unless header
      log.warn 'Ignoring request for types: no header present.  Use "// -header" to extract header.'
    else
      header.clear_types!
      input.each do |e|
        puts "  #{self.class} ======================" if debug?
        header.col_types! e
        puts "  ====================================\n\n" if debug?
      end
      header.finalize_types!
    end
    if debug?
      pp(self: self, col_types: Hash[header.map(&:to_sym).zip(header.map(&:type))])
    end
    app.call(input, env)
  end
end

class Coerce < Pipe
  include Pipe::Process, Pipe::NeedsHeader
  register! :coerce,
            "coerce values into derived or specified types."
  def call input, env
    header = input.header!
    input.map! do | r |
      header.map do |c|
        v = r[c.to_i]
        v = Typing.coerce(v, c.type) if c.type
        v
      end
    end
    app.call(input, env)
  end
end

############################################

class CSVIn < Pipe
  include Pipe::Parse
  include CSVSafe
  register! :'-csv',
  'parse CSV lines'
  # TODO: Potentially refactor into a IOLines base class.
  def call input, env
    i = 0
    input.map! do |e|
      i += 1
      e = e.strip
      csv_parse_line(e, i) unless e.empty?
    end.compact!
    app.call(input, env)
  end
end

class CSVOut < Pipe
  include CSVSafe, Pipe::Format
  register! :'csv-',
  'emit CSV rows'
  # TODO: Potentially refactor into a IOLines base class.
  def call input, env
    i = -1
    input.map!{ |e| csv_generate_line(e, (i += 1)) }
    app.call(input, env)
  end
end

############################################

############################################

class Tee < Pipe
  register! [ :'tee', :t ],
  'duplicate input to one or more output pipelines.'
  attr_reader :outputs
  def init_more!
    super
    @outputs = args
    @outputs.each do | o |
      raise_ "expected pipeline argument: #{o.inspect}" unless Pipe::Pipeline === o
    end
    # pp(outputs: outputs)
  end
  def call input, env
    outputs.each do | output |
      # Pipelines often edit tables in-place.
      # Input must be deep copied for each output.
      output.call(input.dup_deep, env)
    end
    app.call(input, env)
  end
end

############################################

class Join < Pipe
  register! [ :'join', :j ],
  'Join on values between one or more pipelines.'

  def call input, env
    left = input
    a = args.dup
    until a.empty?
      left = join left, a, env
    end
    app.call(left, env)
  end

  def join left, args, env
    a   = args[0 ... 8]
    raise_ "Unexpected args" if a.size < 8
    args[0 ... 8] = []
    l   = [left] + a[0 .. 2]
    op  = a[3]
    r   = a[4 .. -1].reverse
    r[0] = r[0].run!(env)

    l   = JoinSpec.new(*l).complete!
    r   = JoinSpec.new(*r).complete!
    
    j_cols    = l.cols.map{|c| l.alias + c.to_s} + r.cols.map{|c| r.alias + c.to_s}
    j_header  = Header.new(j_cols)
    j_cols    = j_header.cols
    j_table   = Table.new(j_header, [])

    # Build an index of left and right sides:
    j_index = Hash.new{|h, k| h[k] = [ [] , [] ]}
    [[l, 0], [r, 1]].each do | (side, i) |
      side.table.each do | r |
        j_index[r.values_at(*side.join_inds).map(&:to_s)][i] << r.values_at(*side.cols_inds)
      end
    end

    join_rows = lambda do | blk |
      j_index.each do | j_k, (l_rows, r_rows) |
        begin
          l_rows, r_rows = blk.call(l_rows, r_rows)
          l_rows.each do | l_row |
            r_rows.each do | r_row |
              j_row = (l_row || l.empty) + (r_row || r.empty)
              j_table << j_row
            end
          end
        rescue => exc
          raise exc.class, "#{exc.inspect} : in join #{pps(j_k: j_k, l_rows: l_rows.size, r_rows: r_rows.size)}", exc.backtrace
        end
      end
    end
    
    l_empty_r, r_empty_r = [ l.empty ], [ r.empty ]
    case op
    when nil, 'inner', "="
      join_rows.call(lambda { | l_rows, r_rows |
                       [ l_rows,
                         r_rows ]
                     })
    when 'left-outer', 'lo', '/='
      join_rows.call(lambda { | l_rows, r_rows |
                       [ l_rows,
                         r_rows.empty? ? r_empty_r : r_rows ]
                     })
    when 'right-outer', 'ro', '=/'
      join_rows.call(lambda {| l_rows, r_rows |
                       [ l_rows.empty? ? l_empty_r : l_rows,
                         r_rows ]
                     })
    when 'outer', 'full-outer', 'fo', 'o', '/=/'
      join_rows.call(lambda { | l_rows, r_rows |
                       [ l_rows.empty? ? l_empty_r : l_rows,
                         r_rows.empty? ? r_empty_r : r_rows ]
                     })
    else
      raise_ "invalid join op #{op}"
    end
    
    j_table
  end

  class JoinSpec < Struct.new(:table, :alias, :cols, :join, :join_inds, :cols_inds, :empty)
    def complete!
      cols_names = self.cols.split(/\s*,\s*|\s+/)
      join_names = self.join.split(/\s*,\s*|\s+/)
      input_header = table.header
      self.cols       = ['*', '@', ''].include?(self.cols) ? input_header.cols : cols_names.map{|name| input_header.col(name)}
      self.cols_inds  = cols.map(&:to_i)
      self.join       = join_names.map{|name| input_header.col(name)}
      self.join_inds  = join.map(&:to_i)
      self.empty      = [ nil ] * cols.size
      self
    end
  end
end

############################################

module EnumerableTable
  include Enumerable
  def header!
    @header or raise_ "does not have a header"
  end
  # Enumerable:
  def each(&blk)
    _rows.each(&blk)
    self
  end
  def empty? ; _rows.empty? ; end
  def first  ; _rows.first  ; end
  # Array-like:
  def [] i   ; _rows[i]     ; end # Used by transpose
  def size   ; _rows.size   ; end

  # Array-like Mutation:
  def clear        ; _rows_cow.clear               ; end
  def shift        ; _rows_cow.shift               ; end
  def unshift  x   ; _rows_cow.unshift x    ; self ; end
  def pop          ; _rows_cow.pop                 ; end
  def push     x   ; _rows_cow.push x       ; self ; end
  def map!     &b  ; _rows_cow.map! &b      ; self ; end
  def compact! &b  ; _rows_cow.compact! &b  ; self ; end
  def select!  &b  ; _rows_cow.select! &b   ; self ; end
  def compact!     ; _rows_cow.compact!     ; self ; end
  # def []= i, v  ## NOT NEEDED
  def concat enum
    enum = enum._rows if EnumerableTable === enum
    _rows_cow.concat(enum)
    self
  end
  # I/O like:
  def write row ; _rows_cow << row ; self ; end
  alias :<< :write

  def inspect mode = nil
    id = @identifier || "#{'%x' % object_id}"
    str = "#<#{self.class.name} #{id} #{size} #{(@header && @header.cols).inspect}>"
    case mode
    when :rows
      str = String.new << str << "\n"
      str << "#{size} vvvvvvvvvvvvvvvvvvvv\n"
      each{|e| str << e.inspect << "\n"}
      str << "#{size} ^^^^^^^^^^^^^^^^^^^^\n"
    end
    str
  end
end

class Table2
  include EnumerableTable, Logging
  attr_accessor :identifier, :header, :input, :rows
  def initialize header = nil, rows = nil
    @header = header
    @rows   = rows
  end
  def _rows     ; @rows ||   (@input && @input.rows) || @input  ; end
  def _rows_cow ; @rows ||= ((@input && @input.rows) || []).dup ; end
  def header
    @header || (@input && @input.header)
  end
  # Functional: returns new Table
  def map(&blk)
    Table2.new(header, _rows.map(&:blk))
  end
end

class Table
  include EnumerableTable, Logging
  attr_accessor :identifier, :header, :rows

  def initialize header = nil, rows = nil
    @header = header
    @rows = rows || [ ]
  end
=begin
  def identifier= x
    @identifier = x
    ObjectSpace.define_finalizer(self, self.class.finalize_proc("#{'%x' % object_id} creator: #{@identifier}"))
  end
  def self.finalize_proc id
    proc { puts "  ### finalized #{self} #{id}" }
  end
=end
  
  def new header = nil, rows = nil
    x = self.class.new(header, rows)
    x.header ||= @header
    x
  end
  
  def _rows     ; @rows ; end
  def _rows_cow ; @rows ; end
  # Optimization:
  def clear     ; @rows = [ ] ; end

  def dup_deep
    dup.dup_deepen! self
  end
  def dup_deepen! src
    @rows     = @rows.map{|r| r.dup}
    @header &&= @header.dup_deep
    @opts     = @opts.dup
    self
  end
end

class Header
  include Enumerable, Logging
  extend Logging
  
  def inspect
    "#<#{self.class.name} #{"%0x" % object_id} #{name.inspect} #{@cols.inspect}>"
  end

  def initialize cols = nil, opts = nil
    self.cols = cols if cols
    @opts = opts || { }
  end
  attr_reader :cols, :name_to_col, :ind_to_col
  attr_accessor :name, :opts

  def << c
    self.cols = [ *cols, c ]
    self
  end

  def set_cols! cols
    _start_col_mapping!
    cols.each do | c |
      add_col! c
    end
    _finish_col_mapping!
    self
  end

  def add_col! c
    case c
    when Column
      col = c.dup_deep
    when String, Symbol
      col = Column.new(c)
    else
      raise TypeError, "Invalid column name : #{c.inspect} : #{@cols.inspect}"
    end
    _add_col! col
  end

  def _start_col_mapping!
    @cols        = [ ]
    @name_to_col = { }
    @ind_to_col  = { }
    @to_s = @to_h = @row_fn = nil
    self
  end

  def _add_col! col
    if @name_to_col[col.name]
      col.name = :"#{col.name}__#{@cols.size}"
      log.warn "duplicate column #{col.to_s.inspect} will be named #{col.name.to_s.inspect}"
    end
    col.header = self
    col.ind = @cols.size;
    _col_! col
  end
  
  def _col_! col
    @cols << nil while @cols.size <= col.ind
    @cols[col.ind]         = col
    @name_to_col[col.name] = col
    @ind_to_col[col.ind]   = col
    @to_s = @to_h = @row_fn = nil
    col
  end
  
  def to_s
    @to_s ||= @cols.map(&:name).join(',').freeze
  end
  
  def to_h
    @to_h ||= Hash[@cols.map(&:name).zip(@cols.map(&:ind))]
  end

  def _finish_col_mapping!
    self
  end
  
  def dup_deep
    dup.dup_deepen!(self)
  end
  def dup_deepen! src
    @opts &&= @opts.dup # USED ???
    cols = @cols
    _start_col_mapping!
    cols.map(&:dup_deep).each{|col| _add_col! col}
    _finish_col_mapping!
  end
  alias :cols= :set_cols!
  
  def self.clean_col_name c
    c && c.to_s.gsub(/^%|%$/, '').gsub(/[\{\}\[\]\(\)]/, '').gsub(/[^-_\w]/, '_').to_sym
  end

  # Transform row.
  def row r, cols = nll
    row_fn(cols).call(r)
  end
  def col_row r, cols = nil
    (cols || self.cols).map{|c| [c, r[c.to_i]]}
  end
  def row_hash r, cols = nil
    Hash[col_row(r, cols)]
  end
  def row_arry r, cols = nil
    row_fn(cols).call(r)
  end
  def row_fn cols = nil
    @row_fn ||= { }
    @row_fn[cols] ||=
      begin
        inds = self[cols || self.cols].map(&:to_i)
        lambda{|row| row.values_at(*inds)}
      end
  end
  
  def each &blk
    @cols.each(&blk)
    self
  end
  def size ; @cols.size ; end
  
  def [] x
    case x
    when Column  then x
    when Integer then @ind_to_col[x]
    when Symbol  then @name_to_col[x]
    when String  then @name_to_col[x.to_sym]
    when Enumerable then x.map{|x| self[x]}
    else
      nil
    end
  end
  def to_proc
    @to_proc ||= lambda{|x| self[x]}
  end
  alias :call :[]
  
  def col x
    case x
    when Column
      # May be from a different Header.
      col(x.to_sym)
    when Enumerable
      x.map{|x| col(x)}
    else
      self[x] or raise "Unknown column : #{x.inspect} in #{to_h.inspect}"
    end
  end

  def self.parse_column_args args
    cols = args.flat_map do |c|
      c.strip.split(/\s+|\s*,\s*/, -1).map(&:strip)
    end
    cols.reject!(&:empty?)
    cols.map! do | name |
      if name =~ /^([^:]+)(:(.*))?$/
        name, opts = $1, $3 || ''
        case name
        when /^\d+$/
          name = name.to_i
        end
        [ name, opts ]
      else
        raise_ "invalid column specifcation #{args.inspect}"
      end
    end
    cols.map! do | (name, opts) |
      kvs = opts.split(':').map do |kv|
        k, v = kv.split("=", 2)
        [ k.to_sym, v || true ]
      end
      [ name, Hash[kvs] ]
    end
    pp(cols: cols) if debug?
    cols
  end
    
  ###########################
  
  class Column
    include Logging
    attr_accessor :header, :name, :ind, :opts
    attr_reader :to_s
    alias :to_i   :ind
    alias :to_sym :name
    
    def initialize name, ind = nil
      self.name = name
      @ind = ind
      @opts = { }
    end
    
    def inspect
      "#<C #{@name.inspect} #{@ind.inspect} #{@opts.inspect}>"
    end

    def name= name
      @name = name.to_sym
      @to_s = name.to_s.freeze
      @header && @header._col_!(self)
    end

    def opts= opts
      opts.each do | k, v |
        sel = :"#{k}="
        if respond_to?(sel)
          send(sel, v)
        else
          @opts[k] = v
        end
      end
      self
    end
    def copy_to! other
      other.ind  ||= @ind
      other.opts = opts.merge(other.opts)
      other
    end
    def to_proc
      @to_proc ||= lambda{|x| x[@ind]}
    end
    def dup_deep
      dup.dup_deepen!(self)
    end
    def dup_deepen! src
      @opts    = @opts.dup
      @to_proc = nil
      self
    end
  end
end

module Typing
  extend Logging

  module Boolean ; end

  def self.col_type v
    case v
    when nil # inconclusive
      nil
    when String
      # May be inconclusive
      # Remove currency symbols
      v = v.strip.gsub(/[§¤£$Û¢´€]/, '').downcase
      case 
      when v == ''
      # inconclusive
      when BOOLEANS.include?(v)
        Boolean
      when (Integer(v) rescue nil)
        Integer
      when (Rational(v) rescue nil)
        Rational
      # when (BigDecimal(v) rescue nil)
      # ???
      when (Float(v) rescue nil)
        Float
      else
        String
      end
    when Numeric
      Numeric
    when TrueClass, FalseClass
      Boolean
    else
      v.class
    end
  end
  BOOLEANS = [ 'true', 'false' ].freeze

  def self.type_ge t1, t2
    unless x = TYPE_GE[t1][t2]
      ge = type_ge_(t1, t2)
      pp(t1: t1, t2: t2, ge: ge) if debug?
      x = TYPE_GE[t1][t2] = [ ge ]
    end
    x[0]
  end
  TYPE_GE = Hash.new{|h1, k1| h1[k1] = {}}

  def self.type_ge_ t1, t2
    case
    when t1 == nil
      false
    when t2 == nil
      true
    when t1 <= Symbol
      true
    when t1 <= String
      true
    when t1 <= Numeric && ! (t2 <= Numeric)
      false
    when t1 <= Float
      true
    when t1 <= Rational
      case
      when t2 <= Integer
        true
      when t2 <= Float
        false
      else
        true
      end
    when [Boolean, TrueClass, FalseClass].include?(t1)
      case
      when [Boolean, TrueClass, FalseClass, NilClass, nil].include(t2)
        true
      else
        false
      end
    else
      t1 == t2
    end
  end

  def self.coerce x, type
    type_coercer(type).call(x)
  end

  def self.type_coercer type
    TYPE_COERCER[type] ||= TYPE_COERCER[nil]
  end
  TYPE_COERCER = {
    Float    => Proc.new{|x| x.to_f},
    Rational => Proc.new{|x| x.to_r},
    Integer  => Proc.new{|x| x.to_i},
    Symbol   => Proc.new{|x| x.to_s.to_sym},
    Boolean  => Proc.new{|x| x =~ /t/i ? true : false},
    String   => Proc.new{|x| x.to_s},
    nil      => Proc.new{|x| x},
  }
  TYPE_COERCER[TrueClass] = TYPE_COERCER[FalseClass] = TYPE_COERCER[Boolean]

  NAME_TO_TYPE =
    Hash[TYPE_COERCER.keys.map{|cls| [cls && cls.name.sub(/.*::/, ''), cls]}]
  ['TrueClass', 'FalseClass'].map{|s| NAME_TO_TYPE.delete(s)}
  TYPE_TO_NAME =
    Hash[NAME_TO_TYPE.map(&:reverse)]
  NAME_TO_TYPE.values.each{|cls| NAME_TO_TYPE[cls] = cls }
  NAME_TO_TYPE["Numeric"] = ::Numeric
  
  def self.compare type, a, b
    case
    when a.class == b.class
      a <=> b
    when a.nil? && b.nil?
      0
    when a.nil?
      -1
    when b.nil?
      1
    when ! type
      a.to_s <=> b.to_s
    else
      coerce(a, type) <=> coerce(b, type)
    end
  end

  def self.first_superclass classes, cls
    classes
      .each_with_index
      .map do |o,i|
      [cls <= o, o, i]
    end
      .select(&:first)
      .each(&:shift)
      .first
  end

  module Column
    def type         ; opts[:type]      || @type            ; end
    def type= x      ; opts[:type]       = NAME_TO_TYPE[x] ; default_justify! ; end
    def min_width    ; opts[:min_width] || @min_width       ; end
    def min_width= x ; opts[:min_width]  = x.to_i           ; end
    def max_width    ; opts[:max_width] || @max_width       ; end
    def max_width= x ; opts[:max_width]  = x.to_i           ; end
    def justify      ; opts[:justify]   || @justify         ; end
    def justify= x   ; opts[:justify]    = x && x.to_sym    ; end

    def col_type! v
      col_width! v
      v_type = ::Typing.col_type(v)
      new_type = ::Typing.type_ge(v_type, @type) ? v_type : @type
      if debug?
        pp(col_type!: self,
           v: v, v_cls: v.class, v_type: v_type,
           c_type:    type)
        puts
      end
      @type = new_type
      self
    end
    
    def clear_type!
      @type = @min_width = @max_width = nil
      self
    end
    def default_type!
      @type ||= ::String
      default_justify!
    end
    def default_justify!
      @justify = type && type <= Numeric ? :right : nil
      self
    end

    def col_width! v
      width = v.to_s.size
      @min_width = width if (@min_width ||= 99999) > width  
      @max_width = width if (@max_width ||=    -1) < width  
      self
    end

    def coerce v
      Typing.type_coercer(type).call(v)
    end
  end

  module Header
    def col_types? ; @col_types_ready; end
    def col_types! row, cols = self.cols
      @col_types_ready = false
      puts "\ncol_types! #{row.inspect}" if debug?
      cols.each do | c |
        c.col_type! row[c.to_i]
      end
      puts "col_types! #{map(&:type).inspect}\n" if debug?
      self
    end
  
    def clear_types!
      @col_types_ready = false
      each{|c| c.clear_type!}
      self
    end
  
    def finalize_types!
      unless @col_types_ready
        each{|c| c.default_type!}
        @col_types_ready = true
      end
      self
    end
  end
end

class Header
  include Typing::Header
  class Column
    include Typing::Column
  end
end

############

class AsciiTableOut < Pipe
  include Pipe::Format
  register! [ :'txt-', :'t-', :ascii, :text ],
  'emit formatted text table'
  def init_more!
    require 'terminal-table'
    super
  end
  def call input, env
    # NOTE: Terminal::Table cannot stream from Enumerable or to IO.
    header = input.header
    rows   = input.rows

    output = new_table(input)
    title = opts[:title]

    cols = header ? header.cols : [ ]
    
    tt = Terminal::Table.new(rows: rows)

    tt.headings = cols.map(&:to_s) unless cols.empty?
    tt.title = title if title
    tt.style = { :border_top => false,
                 :border_bottom => false,
               }
    cols.each do | c |
      tt.align_column(c.to_i, :right) if c.justify == :right
    end
    
    output << (tt.to_s + "\n")
    app.call(output, env)
  end
end

class MarkdownOut < Pipe
  include Pipe::Format
  register! [ :'md-', :'markdown-' ],
  'emit Markdown table'
  def call input, env
    header = input.header

    title = opts[:title]
    pp(self: self, rows: rows, header: header) if debug?

    format_row = lambda do | row |
      '| ' + (row * ' | ') + " |\n" 
    end
    if header
      c_mw = header.map{|c| [c.max_width || 0, c.name.to_s.size, 4].max }
      format_row_ = format_row
      format_row = lambda do | row, fill = nil |
        format_row_[
          header.map.with_index do |c, i|
            v = row[c.to_i].to_s
            mw = c_mw[i]
            case fill
            when String
              v = fill * mw
              v[-1] = ':' if c.justify == :right
            when :header
              mw = - mw
              v = "%#{mw}s" % v
            else
              mw = c.justify == :right ? mw : - mw
              v = "%#{mw}s" % v
            end
            v
          end
        ]
      end
    end
    input.map! do | row |
      format_row[row]
    end
    if header
      input.unshift format_row[header.map{|_| '---'}, '-']
      input.unshift format_row[header.map(&:to_s), :header]
    end
    app.call(input, env)
  end
end


############

class StructuredOut < Pipe
  include Pipe::Format
  def init_more!
    super
    @seq_delim = '[]'
    @row_delim = '{}'
    @row_sep   = ','
  end
  def call input, env
    output = new_table(input)
    row_delim = self.row_delim
    array_mode = opts[:mode] == 'row'
    row_sep = cols = nil
    if input.header
      cols = input.header.cols
      have_types = cols.any?(&:type)
      col_names = cols.map(&:to_sym)
    else
      array_mode = true
    end
    output << seq_delim[0]
    input.each_shift do | row |
      output << row_sep.to_s << "\n"
      data = if array_mode 
               row
             else
               if have_types
                 row = cols.map do |c|
                   v = row[c.to_i];
                   v = Typing.coerce(v, c.type) if c.type
                   v
                 end
               end
               Hash[col_names.zip(row)]
             end
      pp(row: row, data: data) if debug?
      output << line(data, row_delim)
      row_sep = self.row_sep
    end
    output << ("\n" + seq_delim[1] + "\n")
    app.call(output, env)
  end
  def line row
    raise
  end
  def seq_delim
    @seq_delim ||= make_delim opts[:seq_delim]
  end
  def row_delim
    @row_delim ||= make_delim opts[:row_delim]
  end
  def make_delim cfg
    cfg ? cfg.to_s.gsub(/\s/, '').split('', 2).map(&:to_s) : [nil, nil]
  end
  def row_sep
    opts[:row_sep]
  end
end

class JSONIn < Pipe
  include Pipe::Parse
  register! :'-json',
  'parse JSON'
  def init_more!
    require 'json'
    super
  end
  def call input, env
    stream = input.rows * '' # EXPENSIVE: See deleted RowReader for a broken alternative
    pp(stream: stream) if debug?
    rows = JSON.load(stream)
    raise unless Array === rows
    pp(json: rows)  if debug?
    
    header, keys = header_from_hash_keys(input.header, rows)
    output = new_table(input)
    output.header = header
    pp(in_header: input.header, header: header, key_to_col: key_to_col) if debug?
    rows.each_shift do | row |
      pp(row: row) if debug?
      row = row.values_at(*keys) if Hash === row
      pp(row_: row) if debug?
      output << row
    end
    app.call(output, env)
  end

  def header_from_hash_keys header, rows
    keys = nil
    if Hash === rows.first
      keys = Set.new # Assumes Sets are ordered.
      rows.each do | row |
        keys.merge(row.keys) if Hash === row
      end
      header = keys.empty? ? header : Header.new(keys.to_a)
    end
    [ header, keys ]
  end
end

class JSONOut < StructuredOut
  register! [ :'json-', :json ],
  'emit JSON'
  def init_more!
    require 'json'
    super
  end
  def line row, row_delim
    # TODO: handle alternate row_delim
    JSON.dump(row)
  end
  def row_sep
    super || ','
  end
end

####################################

class ClojureOut < StructuredOut
  register! [ :'edn-', :edn, :clj, :'clj-' ],
  'emit EDN   EDN is native to Clojure.'
  # TODO: use a supported EDN library?
  def sep ; "" ; end
  def line row, row_delim
    case row
    when Hash
      clj_map(row, row_delim)
    else
      clj_vec(row, row_delim)
    end
  end

  def clj_map row, row_delim
    (row_delim[0] || '{') +
    row.map do| (k, v) |
      key_xform(k) + ' ' << val_xform(v)
    end * ' ' +
    + (row_delim[1] || '}')
  end

  def clj_vec row, row_delim
    (row_delim[0] || '[') +
    row.map{|v| val_xform(v)} * ' '
    + (row_delim[1] || ']')
  end
  
  def key_xform k
    case k
    when String, Symbol
      @styles ||= (opts[:key_style] || 'keyword').split(/,/, -1)
      @styles.inject(k.to_s){|k, style| send(:"key_#{style}!", k)}
    else
      val_xform k
    end
  end
  def key_keyword! k
    ":#{k}"
  end
  def key_uncamel! k
    k.gsub(/([a-z])([A-Z])/){|| $1 + '-' + $2}
  end
  def key_downcase! k
    k.downcase
  end
  def key_dash! k
    k.gsub(/[^-\w+]/, '-')
  end

  def val_xform v
    case v
    when Symbol then ":#{v}"
    when String then v.inspect # kinda close?
    when nil    then "nil"
    when Hash       then clj_map(v, @map_delim ||= ['{', '}'])
    when Enumerable then clj_vec(v, @vec_delim ||= ['[', ']'])
    else             v.to_s
    end
  end
end

############

class HTMLOut < Pipe
  include Pipe::NeedsHeader
  include Pipe::Format
  register! [ :'html-', :html ],
  'emit HTML table document.', {
    '--title=' => 'Specify a <title>.',
    '--filtering' => 'Add a full-text filtering field.',
    '--raw=' => 'A list of columns that contain raw HTML.',
    '--head=' => 'Raw HTML placed at bottom of <head>.',
    '--body-head=' => 'Raw HTML placed at the top of <body>.',
    '--body-foot=' => 'Raw HTML placed at bottom of <body>.',
  }
  def init_more!
    super
    @raw_columns = Set.new((opts[:raw] || '')
                             .strip.split(/\s+|\s*,\s*/, -1)
                             .map(&:to_sym)
                             .uniq)
    self
  end
  def call input, env
    header = input.header!
    cols = header.cols
    colspan = 1 + cols.size
    right = {style: 'text-align: right;'}
    output = new_table(input)
    h = HTML.new(output)
    h.html do
      h.head do
        x = opts[:title] and h.title(x)
        h << HTML_HEAD
        x = opts[:head]  and h.raw!(x)
      end
      h.body do
        x = opts[:body_head] and h.html(x)
        h.div(id: 'cx-content', class: 'cx-content') do
        x = opts[:title] and h.div({id: 'cx-title', class: 'cx-title'}, x)
        h.table(id: 'cx-table', class: 'cx-table') do
          h.thead do
            if opts[:filtering]
              h.tr(class: 'cx-filter') do
                h.span(class: 'cx-filter') do
                  h.th(class: 'cx-filter', colspan: colspan) do
                    h.input({type: "text",
                             id: 'cx-filter',
                             class: "cx-filter",
                             onkeyup: "cx_filter_rows()",
                             placeholder: "#{UNICODE[:search]} Filter..."})
                  end
                end
              end
            end
            h.tr do
              a = {class: 'cx-column-header'}
              h.th(a.merge("data-sort-method" => :number), "#")
              cols.each do | c |
                a = a.merge("data-sort-method" => :number) if c.justify == :right
                h.th(a, c)
              end
            end
          end
          size = input.size
          h.tbody({id: "cx-table-tbody"}) do
            td_attrs = cols.map{|c| c.justify == :right ? right : nil}
            raw_cols = cols.map{|c| @raw_columns.include?(c.name)}
            inds = cols.map{|c| header[c].to_i }
            ri = 0
            input.each_shift do | r |
              ri += 1
              row_tooltip = "Row #{ri} / #{size}"
              # row_tooltipe << ": #{r[inds[0]]}" # TODO: make this optional
              h.tr(title: row_tooltip) do
                h.td(right, ri)
                inds.each_with_index do | ci, i |
                  h.td(td_attrs[i]) do
                    if raw_cols[i]
                      h.raw!(r[ci])
                    else
                      h.text(r[ci])
                    end
                  end
                end
              end
            end
          end
        end
        end
        x = opts[:body_foot] and h.raw!(x)
      end
      h << HTML_FOOT
    end
    app.call(output, env)
  end

  UNICODE = {
    # Left-Pointing Magnifying Glass : U+1F50D
    search: "🔍",
  }

  class HTML < Object # BasicObject
    def initialize out
      @out = out
      @html_sep   = ::Hash[%w(span td th title meta).map{|t| [t.to_sym, ""]}]
      @html_open  = ::Hash.new{|h, tag| h[tag.to_sym] = "<#{tag}>".freeze}
      @html_close = ::Hash.new{|h, tag| h[tag.to_sym] = "</#{tag}>".freeze}
    end
    
    def _tag tag, attrs = nil, content = nil, &blk
      tag = tag.to_sym
      case
      when ::Hash === attrs
        attrs = attrs.map{|k,v| v.nil? || " #{k}='#{v}'"}.compact
        attrs = attrs.empty? ? nil : attrs.join(' ')
      when ::String === attrs && ! content
        content = attrs
        attrs = nil
      end
      ws = @html_sep[tag] ||= "\n"

      self << (attrs ? "<#{tag} #{attrs}>" : @html_open[tag]) << ws

      case
      when content
        close = true
        text(content)
      when blk
        close = true
        yield self
      else
        close = false
      end
      
      self << @html_close[tag] << "\n" if close
      nil
    end
    
    def raw! x ; @out.write x.to_s ; self ; end
    alias :<< :raw!
    def text x
      raw! ::CGI::escapeHTML(x.to_s)
    end

    def method_missing sel, *args, &blk
      _tag(sel, *args, &blk)
    end
  end
  
  HTML_HEAD = <<END
<style type="text/css">
body {
font-family: Arial, Helvetica, sans-serif;
background-color: #000;
color: #eee;
}
.cx-title {
  text-align: center
}
div.cx-content {
  display: inline-block;
}
table {
  border-collapse: collapse;
}
thead th {
  background-color: #333;
  border: 0.1rem solid #111
}
tr:hover {
  background-color: #444;
}
tr:nth-child(even) {
  background-color: #222;
}
th, td {
  padding: 0.5rem 1rem;
  border-bottom: 1px solid #555;
}
a:link {
  color: inherit;
  text-decoration: none;
}
a:active {
  color: inherit;
  text-decoration: none;
}
a:visited {
  color: inherit;
  text-decoration: none;
}
a:hover {
  color: inherit;
  text-decoration: underline;
}

# https://css-tricks.com/position-sticky-and-table-headers/
table.cx-table {
  position: relative,
}
th.cx-column-header {
  position: sticky;
  top: 0;
}

th.cx-filter {
  position: sticky;
  left: 0;
}
input.cx-filter {
  width: 15em;
  float: left;
}

</style>
END
  
  HTML_FOOT = <<END
<script type="text/javascript">
/*!
 * tablesort v5.1.0 (2018-09-14)
 * http://tristen.ca/tablesort/demo/
 * Copyright (c) 2018 ; Licensed MIT
*/
!function(){function a(b,c){if(!(this instanceof a))return new a(b,c);if(!b||"TABLE"!==b.tagName)throw new Error("Element must be a table");this.init(b,c||{})}var b=[],c=function(a){var b;return window.CustomEvent&&"function"==typeof window.CustomEvent?b=new CustomEvent(a):(b=document.createEvent("CustomEvent"),b.initCustomEvent(a,!1,!1,void 0)),b},d=function(a){return a.getAttribute("data-sort")||a.textContent||a.innerText||""},e=function(a,b){return a=a.trim().toLowerCase(),b=b.trim().toLowerCase(),a===b?0:a<b?1:-1},f=function(a,b){return function(c,d){var e=a(c.td,d.td);return 0===e?b?d.index-c.index:c.index-d.index:e}};a.extend=function(a,c,d){if("function"!=typeof c||"function"!=typeof d)throw new Error("Pattern and sort must be a function");b.push({name:a,pattern:c,sort:d})},a.prototype={init:function(a,b){var c,d,e,f,g=this;if(g.table=a,g.thead=!1,g.options=b,a.rows&&a.rows.length>0)if(a.tHead&&a.tHead.rows.length>0){for(e=0;e<a.tHead.rows.length;e++)if("thead"===a.tHead.rows[e].getAttribute("data-sort-method")){c=a.tHead.rows[e];break}c||(c=a.tHead.rows[a.tHead.rows.length-1]),g.thead=!0}else c=a.rows[0];if(c){var h=function(){g.current&&g.current!==this&&g.current.removeAttribute("aria-sort"),g.current=this,g.sortTable(this)};for(e=0;e<c.cells.length;e++)f=c.cells[e],f.setAttribute("role","columnheader"),"none"!==f.getAttribute("data-sort-method")&&(f.tabindex=0,f.addEventListener("click",h,!1),null!==f.getAttribute("data-sort-default")&&(d=f));d&&(g.current=d,g.sortTable(d))}},sortTable:function(a,g){var h=this,i=a.cellIndex,j=e,k="",l=[],m=h.thead?0:1,n=a.getAttribute("data-sort-method"),o=a.getAttribute("aria-sort");if(h.table.dispatchEvent(c("beforeSort")),g||(o="ascending"===o?"descending":"descending"===o?"ascending":h.options.descending?"descending":"ascending",a.setAttribute("aria-sort",o)),!(h.table.rows.length<2)){if(!n){for(;l.length<3&&m<h.table.tBodies[0].rows.length;)k=d(h.table.tBodies[0].rows[m].cells[i]),k=k.trim(),k.length>0&&l.push(k),m++;if(!l)return}for(m=0;m<b.length;m++)if(k=b[m],n){if(k.name===n){j=k.sort;break}}else if(l.every(k.pattern)){j=k.sort;break}for(h.col=i,m=0;m<h.table.tBodies.length;m++){var p,q=[],r={},s=0,t=0;if(!(h.table.tBodies[m].rows.length<2)){for(p=0;p<h.table.tBodies[m].rows.length;p++)k=h.table.tBodies[m].rows[p],"none"===k.getAttribute("data-sort-method")?r[s]=k:q.push({tr:k,td:d(k.cells[h.col]),index:s}),s++;for("descending"===o?q.sort(f(j,!0)):(q.sort(f(j,!1)),q.reverse()),p=0;p<s;p++)r[p]?(k=r[p],t++):k=q[p-t].tr,h.table.tBodies[m].appendChild(k)}}h.table.dispatchEvent(c("afterSort"))}},refresh:function(){void 0!==this.current&&this.sortTable(this.current,!0)}},"undefined"!=typeof module&&module.exports?module.exports=a:window.Tablesort=a}();

/*!
 * tablesort v5.1.0 (2018-09-14)
 * http://tristen.ca/tablesort/demo/
 * Copyright (c) 2018 ; Licensed MIT
*/
!function(){var a=function(a){return a.replace(/[^\-?0-9.]/g,"")},b=function(a,b){return a=parseFloat(a),b=parseFloat(b),a=isNaN(a)?0:a,b=isNaN(b)?0:b,a-b};Tablesort.extend("number",function(a){return a.match(/^[-+]?[£\x24Û¢´€]?\d+\s*([,\.]\d{0,2})/)||a.match(/^[-+]?\d+\s*([,\.]\d{0,2})?[£\x24Û¢´€]/)||a.match(/^[-+]?(\d)*-?([,\.]){0,1}-?(\d)+([E,e][\-+][\d]+)?%?$/)},function(c,d){return c=a(c),d=a(d),b(d,c)})}();

  new Tablesort(document.getElementById('cx-table'));

/*!
 * Basic row filtering.
 */
var cx_filter_timeout = null;
function cx_filter_rows() {
  if ( ! cx_filter_timeout ) 
    cx_filter_timeout = setTimeout(function() {cx_filter_rows_now();}, 50);
}
function cx_filter_rows_now() {
  // Declare variables
  var input = document.getElementById("cx-filter");
  var filter = input.value.trim().toUpperCase();
  var table = document.getElementById("cx-table");
  var tbody = document.getElementById("cx-table-tbody");
  var tr = tbody.getElementsByTagName("tr");

  for (i = 0; i < tr.length; i++) {
    var tds = tr[i].getElementsByTagName("td")
    var display = "";
    if ( ! (filter === '') ) {
display = "none";
    for (j = 1; j < tds.length; j++) {
      var td = tds[j];
      var txtValue = td.textContent || td.innerText;
      if (txtValue.toUpperCase().indexOf(filter) > -1) {
        display = "";
        break;
      }
    }
    }
    tr[i].style.display = display;
  }
  if ( cx_filter_timeout ) {
    var tmp = cx_filter_timeout;
    cx_filter_timeout = null;
    clearTimeout(tmp);
  }
}

</script>
END
end

######################################

class SQLOut < Pipe
  include Pipe::Format
  attr_reader :input, :header, :output, :table
  register! :'sql-',
            'Generate INSERT INTO or CREATE TABLE SQL statements   '
  def table
    @table ||= opts[:table] || @header.name or raise_ "unspecifed table name"
  end
  def call input, env
    @header = input.header!
    @input = input
    @output = new_table(input)
    [:create, :insert].each do |action|
      if opts[action]
        send(:"#{action}!")
      end
    end
    app.call(output, env)
  end

  def create!
    output <<<<"END"
CREATE #{opts[:temp] && "TEMPORARY "}TABLE #{sql_identifer(table)}
(
#{header.map{|c| "  " + sql_column_def(c)} * ",\n"}
);
END
  end
  def sql_column_def col
    "#{col.name} #{type_to_sql_type col}"
  end
  def type_to_sql_type col
    type = col.type
    type = String if type == Symbol
    sql_types = {
      Float   => "FLOAT",
      Integer => "INT",
      Typing::Boolean => "CHAR(1)",
      String  => "VARCHAR(#{col.max_width || 255})",
      Object  => "<<UNTYPED>>",
    }
    cls = Typing.first_superclass(sql_types.keys, type)
    sql_types[cls.first]
  end
  
  def insert!
    sql_insert_into = <<"END"
INSERT INTO #{sql_identifer(table)}
  #{sql_columns(header)}
VALUES
END
    sep = "  "
    input.each do |r|
      output << sql_insert_into
      output << sep << sql_row(r)
      if opts[:many_inserts]
        output << ";\n"
      else
        sql_insert_into = nil
        sep = ",\n  "
      end
    end
    output << ";\n" unless opts[:many_inserts]
  end
  def sql_columns cols
    sql_list cols.map{|c| sql_identifer(c)} # ??? may require quoting
  end
  def sql_identifer name
    name.to_s # TODO: proper escape
  end
  def sql_row row
    sql_list @header.map{|c| sql_val(row[c.to_i])}
  end
  def sql_list arr
    String.new << '(' << (arr.map(&:to_s) * ', ') << ')'
  end
  def sql_val v # TODO: proper string escape.
    case v
    when nil
      "NULL"
    when String, Symbol
      "'" + v.to_s + "'" # ??? good enough?
    else
      v.to_s
    end
  end
end

######################################

class CommandPipe < Pipe
  include Pipe::Process
  register! [ :cmd,  :- ],
            'pipe rows thru an external command.  Column references "%NAME%" are replaced with column index + 1.'
  attr_accessor :command

  def init_more!
    super
    @command = args
    @column_offset = (opts[:column_offset] || 1).to_i
    @m = Mutex.new
  end
  def inspect_pipe mode = nil
    @command.inspect
  end
  
  def call input, env
    stdin = stdout = wait_thr = wt = rt = nil
    reraise do
      output = new_table(input)
      cmd = command
      if header = input.header 
        rx = Regexp.new("%(" + header.map{|c| Regexp.quote(c.to_s)} * '|' + ")%")
        cmd = cmd.map do | arg |
          arg.gsub(rx){|m| header[$1.to_sym].to_i + @column_offset}
        end
      end
      stdin, stdout, wait_thr = Open3.popen2(*cmd)
      wt = writer! input , stdin
      rt = reader! output, stdout
      wt.join
      rt.join
      wait_thr.value # Fail on command exit code ???
      app.call(output, env)
    end
  ensure
    stdin.close  rescue nil
    stdout.close rescue nil
    wt.kill      rescue nil
    rt.kill      rescue nil
    unless $!
      raise_ wt[:name], wt[:exc] if wt && wt[:exc]
      raise_ rt[:name], rt[:exc] if rt && rt[:exc]
    end
  end

  def writer! input, io
    Thread.new do
      Thread.current[:name] = "#{self.class} writer"
      with_io io do
        input.each_shift do | e |
          io.write e.to_s
        end
      end
    end
  end
  
  def reader! output, io
    Thread.new do
      Thread.current[:name] = "#{self.class} reader"
      with_io io do
        until io.eof?
          line = io.readline
          output << line
        end
      end
    end
  end
  
  def with_io io
    yield
  rescue => exc
    Thread.current[:exc] = exc
    raise
  ensure
    io.close
  end

  def pp *args
    @m.synchronize do
      super
    end
  end
end

######################################

module DestructiveEach
  def each_shift
    yield shift until empty?
  end
  def each_pop
    yield pop until empty?
  end
end

class Array
  include DestructiveEach
end
class Table
  include DestructiveEach
end
end

######################################

module CX
  Logging.raise_cls = Error
end

##################################
# EOF

