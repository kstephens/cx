# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'

module CX
  class Join < Pipe
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
      j_index.each do | j_k, (ls, rs) |
        begin
          ls, rs = blk.call(ls, rs)
          ls.each do | l |
            rs.each do | r |
              j_row = (l || l.empty) + (r || r.empty)
              j_table << j_row
            end
          end
        rescue => exc
          raise exc.class, "#{exc.inspect} : in join #{pps(j_k: j_k, ls: ls.size, rs: rs.size)}", exc.backtrace
        end
      end
    end
    
    le, re = [ l.empty ], [ r.empty ]
    case op
    when nil, 'inner', "="
      join_rows.call(lambda { | l, r |
                       [ l, r ]
                     })
    when 'left-outer', 'lo', '/='
      join_rows.call(lambda { | l, r |
                       [ l,
                         r.empty? ? re : r ]
                     })
    when 'right-outer', 'ro', '=/'
      join_rows.call(lambda {| l, r |
                       [ l.empty? ? le : l,
                         r ]
                     })
    when 'outer', 'full-outer', 'fo', 'o', '/=/'
      join_rows.call(lambda { | l, r |
                       [ l.empty? ? le : l,
                         r.empty? ? re : r ]
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

end
