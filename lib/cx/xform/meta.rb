# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# MetaIn:
#   aliases:
#   synopsis: Calculates various column metadata.
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.csv // -h // -meta // h-'

# :COMMAND:
# MetaOut:
#   aliases:
#   synopsis: Generate a table of column metadata.
#   args: []
#   opts: {}
#   examples:
#     - 'cx in SOME.csv // -h // -meta // meta- // h-'
#     - 'cx in SOME.csv // -h // parse // -meta // meta- // h-'

# :COMMAND:
# SetMeta:
#   aliases:
#   synopsis: Set column meta.
#   args: []
#   opts: {}
#   examples:
#     - "cx in SOME.csv // -h // -meta // set-meta 'a:max_size=20;align=right' // md"
#     - "cx in SOME.csv // -h // -meta // set-meta 'a:max_size=20;align=right;order=9' //  meta- // cut name,order,max_size,align // md"
#     - "cx in SOME.csv // -h // -meta // set-meta 'c:name=newname;order=-1' // md"

module CX
  module Xform
    class MetaIn
      include SelectColumns, Xform
      
      def call input, env
        columns = column_args!(input).or_all!.columns
        
        header = input.header

        m = header.meta
        if columns.size == header.size
          m.clear!
        end
        m.name = m.name_ = env[:input_name] || :__INPUT__
        m.min_size = 0
        m.max_size = input.size

        columns.each do |c|
          m = c.meta
          m.clear!
          m.type  = nil if opts[:clear_type]
          m.name  = c.name
          m.name_ = c.name_
          m.index = c.index
          m.order = c.order
        end

        hm = header.meta
        r_blanks = r_nulls = 0
        input.each do | r |
          columns.each do | c |
            v = r[c]
            c.meta.update! v
          end
        end
        if columns.size == header.size
          header.meta.blanks += 1 if r_blanks == header.size
          header.meta.nulls  += 1 if r_nulls  == header.size
        end
        
        columns.each do | c |
          m = c.meta
          if m.type_inferred && m.type_inferred <= ::Numeric
            m.align_inferred = :right
          end
        end

        input
      end
    end

    class MetaOut
      include SelectColumns, Xform

      def call input, env
        columns = column_args!(input).or_all!.columns
        output = input.header.meta.table
        columns.each do | c |
          output << c.meta.to_h
        end
        MetaIn.new.call(output, env)
      end
    end

    class SetMeta
      include SelectColumns, Xform

      def call input, env
        column_args!(input).bound.each do | ca |
          c = ca.column
          c.name = ca.opts[:name] if ca.opts[:name]
          c.meta.update(ca.opts)
          c.meta.update_column! c
        end
        input
      end
    end
  end
end

