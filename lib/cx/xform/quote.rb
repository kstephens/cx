# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/column_args'

# :COMMAND:
# Quote:
#   aliases: q
#   synopsis: Quote string values that would be ambigous or unprintable.
#   args: []
#   opts:
#     mode: "maybe, everything, always"
#     strings-only: Ignore non-strings.

module CX
  module Xform
    class Quote
      include SelectColumns, Xform
      
      def call input, env
        @strings_only = opts.fetch(:strings_only, false)
        @mode =
          case opts.fetch(:mode, "maybe")
          when /m/i
            :maybe
          when /e/i
            :everything
          when /a/i
            :always
          else
            raise_ "Invalid mode #{mode.inspect}"
          end

        columns = column_args!(input).or_all!.columns
        
        input.each do | r |
          columns.each do | c |
            v = r[c]
            next if @strings_only && ! String === v
            case @mode
            when :maybe
              v = v.to_s
              q = v.inspect
              if v != q.gsub(/^"|"$/, '').strip
                r[c] = q
              end
            when :everything
              r[c] = v.to_s.inspect
              c.meta.type = 
              c.meta.type_inferred = ::String
            when :always
              r[c] = v.inspect
              c.meta.type = 
                c.meta.type_inferred = ::String
            end
          end
        end
        input
      end
    end
  end
end

