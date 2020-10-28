# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class HeaderIn < Pipe
  include Pipe::Parse, Pipe::ColumnsFromArgs
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
  def call input, env
    if input.header
      input.unshift input.header.map(&:to_s)
    end
    app.call(input, env)
  end
end


class Debug < Pipe
  include Pipe::Diagnostic
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

class Noop < Pipe
  include Pipe::Diagnostic
  def call input, env
    app.call(input, env)
  end
end

################################

class Rowid < Pipe
  include Pipe::Process
  def call input, env
    col_name = (opts[:name] || :__rowid__).to_sym
    type = (opts[:type] || "integer").to_s
    header = input.header!
    row_fn = header.row_fn
    cols = [ col_name ] + header.cols
    header.cols = cols
    col = header[col_name]

    case type
    when 'uuid'
      require 'securerandom'
      gen = lambda { || SecureRandom.uuid }
      
      col.type = String
      col.min_width = col.max_width = gen.call.size
    else
      i = (opts[:start] || 1).to_i
      i -= 1
      gen = lambda { || i += 1 }
      col.type = Integer
      # + 1 to handle negative start
      max_i = i + input.rows.size
      col.min_width = i.to_s.size
      col.max_width = (Math.log10(max_i) + 1).to_i + 1 + 1
    end

    input.map! do | r |
      r = row_fn.call(r)
      r.unshift(gen.call())
    end

    app.call(input, env)
  end
end

################################

class Strip < Pipe
  include Pipe::Process
  def call input, env
    input.each do | row |
      row.each do |v|
        next unless v
        v.strip!
        if opts[:ansi]
          v.gsub!(/\e\[[^m]*m/, '')
        end
      end
    end
    app.call(input, env)
  end
end

class Awesome < Pipe
  include Pipe::Process
  def call input, env
    require 'awesome_print'
    output = new_table

    # awesome_print-1.8.0/lib/awesome_print/inspector.rb:63: warning: Capturing the given block using Proc.new is deprecated; use `&block` instead
    _VERBOSE = $VERBOSE
    begin
      $VERBOSE = nil
      output.push(input.rows.ai)
    ensure
      $VERBOSE = _VERBOSE
    end
    app.call(output, env)
  end
end

class Grep < Pipe
  include Pipe::Process
  def call input, env
    col_opts = []; a = args.dup
    until a.empty?
      x = Header.parse_column_args([a.shift], false)
      rx = a.shift or raise "grep: missing pattern"
      col_opts << [ x[0], rx ]
    end
    fns = col_opts.map do |((c, opts), rx)|
      rx = Regexp.new(rx)
      if opts[:v] || opts[:-]
        lambda do | str |
          ! rx.match?(str)
        end
      else
        lambda do | str |
          rx.match?(str)
        end
      end
    end
    cols = input.header!.col(col_opts.map(&:first).map(&:first))
    row_fn = input.header.row_fn(cols)
    input.select! do | r |
      r = row_fn.call(r)
      r.zip(fns).all?{|(v,fn)| fn.call(v.to_s)}
    end
    app.call(input, env)
  end
end

class Transpose < Pipe
  include Pipe::Process
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

end
