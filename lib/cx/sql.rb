# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/pipe'

module CX
class SqlOut < Pipe
  include Pipe::Format
  attr_reader :input, :header, :output, :table
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
    env[:content_type] = 'text/plain' # application/x-sql ?
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

end
