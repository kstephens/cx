# frozen_string_literal: true

require 'cx/xform/cmd'

module CX
  module Xform
    class Datamash
      include Xform

      def call input, env
        cmd = Cmd.new
        field_sep = "\001"
        cmd.command = [ "datamash", "--headers", "--sort", "--field-separator=#{field_sep}" ] + args
        table_writer = DelimitedOut.new
        table_reader = DelimitedIn.new
        table_writer.field_sep = table_reader.field_sep = field_sep
        cmd.write_fn = lambda do | io |
          table_writer.call(input, env)
        end
        cmd.read_fn = lambda do | io |
          Table.new(io.readlines(taable_reader.record_sep))
        end
      end
    end
  end
end
