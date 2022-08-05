# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'cx/column_args'

# :COMMAND:
# Quote:
#   aliases: q
#   synopsis: Quote string values that would be ambigous or unprintable.
#   has_column_args: true
#   arguments: []
#   options:
#     mode=maybe,everything,always : 'When to quote.  Default: "maybe"'
#     strings-only: Ignore non-strings.

module CX
  module Xform
    class Quote
      include SelectColumns, Xform
      
      def call input, env
        @strings_only = opts.fetch(:strings_only, false)
        columns = column_args!(input).or_all!.columns
        # ??? : not exactly : see @strings_only
        # columns.each{|c| c.meta.type = c.meta.type_inferred = ::String }

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

        fn = quote_fn
        input.each do | r |
          columns.each do | c |
            v = r[c]
            # ??? || c.meta.type == ::String
            next if @strings_only && ! String === v
            r[c] = fn.call[c, v]
          end
        end
        input
      end

      def quote_fn
        case @mode
        when :maybe
          proc do | c, v |
            s = v.to_s
            q = s.inspect
            s != q.gsub(/^"|"$/, '').strip ? q : s
          end
        when :everything
          proc do | c, v |
            c.meta.type = c.meta.type_inferred = ::String
            v.to_s.inspect
          end
        when :always
          proc do | c, v |
            c.meta.type = c.meta.type_inferred = ::String
            v.inspect
          end
        end
      end
    end
  end
end

