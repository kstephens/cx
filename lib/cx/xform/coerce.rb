# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# Coerce:
#   aliases: 
#   synopsis: Coerce columns by inferred types.
#   args: []
#   opts: {}

module CX
  module Xform
    class Coerce
      include Xform
      def call input, env
        @cleared = Set.new
        columns = ColumnArgs.new.
          parse!(args).
          bind!(input.header).
          or_all!.
          columns
        input.each do | r |
          columns.each do | c |
            old_v = r[c]
            new_v = c.meta.type_object.coerce(old_v)
            unless new_v.nil?
              unless new_v == old_v && new_v.class == old_v.class
                unless @cleared.include?(c)
                  @cleared << c
                  c.meta.clear!
                  c.meta.type = nil
                  c.meta.type_inferred = nil
                end
              end
              r[c] = new_v
            end
          end
        end
        input
      end
    end
  end
end

