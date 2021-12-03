# frozen_string_literal: true

require 'cx'
require 'cx'
require 'cx/xform'
require 'cx/xform/record'

# :COMMAND:
# SqlOut:
#   aliases: sql-
#   synopsis: Generates CSV lines.
#   args: []
#   opts:
#     table: Table name
#     transaction: Emit a TRANSACTION block.
#     rollback: Emit a ROLLBACK statement.
#     commit: Emit a COMMIT statement.
#     create: Emit a CREATE TABLE statement.
#     temporary: CREATE TEMPORARY TABLE statement.
#     insert: Emit INSERT INTO statements.
#     
#     

module CX
  module Xform
    class SqlOut
      include OutputFormat, RecordOut
      attr_reader :input, :header, :output, :table

      def initialize!
        super
      end

      def call input, env
        @input = input
        @header = input.header
        @output = make_output
        @table = opts[:table] || @header.meta.name or raise_ "unspecifed table name"
        # binding.pry
        do_actions!
        env[:content_type] = 'text/plain' # application/x-sql ?
        result = @output
        @input = @header = @output = @table = nil
        result
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
        self <<<<"END"
START TRANSACTION;
END
      end

      def commit!
        self <<<<"END"
COMMIT;
END
      end

      def rollback!
        self <<<<"END"
ROLLBACK;
END
      end
  
      def create!
        self <<<<"END"
CREATE #{opts[:temporary] && "TEMPORARY "}TABLE #{sql_identifer(table)}
(
#{header.map{|c| "  " + sql_column_def(c)} * ",\n"}
);
END
      end

      def sql_column_def col
        "#{col.name_} #{type_to_sql_type col}"
      end

      def type_to_sql_type col
        case cls = col.meta.type_
        when Symbol, nil
          cls = String
        end
        sql_types = {
          BigDecimal => 'NUMERIC',
          Float   => "FLOAT",
          Integer => "INT",
          Boolean => "CHAR(1)",
          String  => "VARCHAR(#{col.meta.max_size || 255})",
          Object  => "TEXT",
        }
        # cls = Typing.first_superclass(sql_types.keys, type)
        sql_types[cls] || sql_types[Object]
      end

      def << str
        # puts str; binding.pry
        @output << [ str.to_s ]
        self
      end
    
    def insert!
      sql_insert_into = <<"END"
INSERT INTO #{sql_identifer(table)}
  #{sql_columns(header)}
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

    def sql_columns cols
      sql_list cols.map{|c| sql_identifer(c.name_)} # ??? may require quoting
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

