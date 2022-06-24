# frozen_string_literal: true

require 'cx'
require 'cx'
require 'cx/xform'
require 'cx/xform/record'

# :COMMAND:
# SqlOut:
#   aliases: sql-
#   synopsis: Generates CSV lines.
#   has_column_args: true
#   args: []
#   opts:
#     table=: Table name.
#     transaction: Emit a TRANSACTION block.
#     rollback: Emit a ROLLBACK statement.
#     commit: Emit a COMMIT statement.
#     create: Emit a CREATE TABLE statement.
#     temporary: CREATE TEMPORARY TABLE statement.
#     insert: Emit INSERT INTO statements.
#     varchar-size=: 'VARCHAR(size). Default: 255.'
#   examples:
#     - cx in SOME.csv // -h // parse // sql- --table=SOME_TABLE --create
#     - cx in SOME.csv // -h // parse // sql- --table=SOME_TABLE --insert
#     - "cx in SOME.csv // -h // parse // cut a b c // parse // meta= 'a:sql_type=VARCHAR(5)' // sql- --table=SOME_TABLE a b 'c:type=NUMERIC;default=-1' --create --temporary"
#     - "cx in SOME.csv // -h // cut a b c // parse // meta= 'a:sql_type=VARCHAR(5)' // sql- --table=SOME_TABLE --insert"
#

module CX
  module Xform
    class SqlOut
      include SelectColumns, OutputFormat, RecordOutBase
      attr_reader :input, :columns, :output, :table

      # TODO: handle dialects: Postgres, Oracle, Sqlite, etc.
      def call input, env
        @input = input
        @columns = column_args!(input).wildcards!.or_all!
        @output = make_output
        @table = opts[:table] || input.header.meta.name or raise_ "unspecifed table name"
        @varchar_size = opts.fetch(:varchar_size, 255)
        
        @columns.each{|ca| sql_type(ca)}

        do_actions!

        env[:content_type] = 'text/plain' # application/x-sql ?
        @output.tap{|_| @input = @columns = @output = @table = nil }
      end

      def do_actions!
        actions = [:transaction, :create, :insert]
          .select{|action| opts[action]}
          .compact
        case
        when ! actions.include?(:transaction)
        when opts[:rollback] && opts[:commit]
          actions << :rollback
        when opts[:temporary]
          actions << :create
        when opts.fetch(:commit, true)
          actions << :commit
        end
        actions.uniq.each do |action|
          send(:"#{action}!")
          self << "\n"
        end
      end

      def transaction!
        self << <<"END"
START TRANSACTION;
END
      end

      def commit!
        self << <<"END"
COMMIT;
END
      end

      def rollback!
        self << <<"END"
ROLLBACK;
END
      end
  
      def create!
        self << <<"END"
CREATE #{opts[:temporary] && "TEMPORARY "}TABLE #{sql_identifer(table)}
(
#{@columns.map{|ca| "  " + sql_column_def(ca)} * ",\n"}
);
END
      end

      def sql_column_def col_arg
        col = col_arg.column
        sql = "#{col.name_} #{col_arg.opts[:type]}"
        if default_value = col_arg.opts[:default]
          sql += " DEFAULT #{sql_val(default_value, col_arg)}"
        end
        sql
      end

      def sql_type col_arg
        col = col_arg.column
        case cls = col.meta.type_
        when Symbol, nil
          cls = String
        end
        sql_types = {
          BigDecimal => 'NUMERIC',
          Float   => "FLOAT",
          Integer => "INT",
          Boolean => "CHAR(1)",
          String  => "VARCHAR(#{@varchar_size})",
          Object  => "TEXT",
        }
        # cls = Typing.first_superclass(sql_types.keys, type)
        col_arg.opts[:default] ||= col.meta.opts[:sql_default]
        col_arg.opts[:type]    ||= col.meta.opts[:sql_type] || sql_types[cls] || sql_types[Object]
      end

      def << str
        # puts str; binding.pry
        @output << [ str.to_s ]
        self
      end
    
    def insert!
      sql_insert_into = <<"END"
INSERT INTO #{sql_identifer(table)}
  #{sql_columns(@columns)}
VALUES
END
      sep = "  "
      input.each do |r|
        self << sql_insert_into
        self << sep << sql_row(r)
        if opts[:many_inserts]
          self << ";\n\n"
        else
          sql_insert_into = nil
          sep = ",\n  "
        end
      end
      self << ";\n" unless opts[:many_inserts]
      end
    end

    def sql_columns col_args
      sql_list col_args.map{|ca| sql_identifer(ca.column.name_)} # ??? may require quoting
    end

    def sql_identifer name
      name.to_s # TODO: proper escape
    end

    def sql_row row
      sql_list @columns.map{|ca| sql_val(row[ca.column], ca)}
    end

    def sql_list arr
      String.new << '(' << (arr.map(&:to_s) * ', ') << ')'
    end

    # TODO: proper string escape.
    def sql_val v, col_arg
      return "NULL" if v.nil?
      case col_arg.opts[:type]
      when /^(TEXT|CHAR|VARCHAR)/i # ??? do more?
        # ??? good enough?
        v = v.to_s.
          inspect.
          gsub(/^"|"$/, '').
          gsub("\\\"", '"').
          gsub("'", "''")
        "'" + v + "'"
      else
        v.to_s
      end
    end
  end
end

