# frozen_string_literal: true

require 'cx'
require 'cx/xform'

# :COMMAND:
# HeaderIn:
#   aliases: [ -h ]
#   synopsis: Interprets first row as a column name header.
#   inverse: [ 'h-' ]
#   args: []
#   opts:

# :COMMAND:
# HeaderOut:
#   aliases: [ h- ]
#   synopsis: Emits column names as first row.
#   inverse: [ '-h' ]
#   args: []
#   opts:
#     '--meta-columns=meta-column,...': 'Emit each meta-column for each column.'

module CX
  module Xform
    class HeaderIn
      include Xform
      def call input, env
        cols = input.shift.map do | c, v |
          v.to_s
        end
        input.header = Header.new(cols)
        input
      end
    end
    
    class HeaderOut
      include Xform
      def initialize!
        super
        @meta_columns = (opts[:meta_columns] || "").
          split(/\s*,\s*/).
          map(&:to_sym)
      end
      
      def call input, env
        if @meta_columns.empty?
          output = Table.new([], input.header.dup, input.meta.dup)
          output << input.header.map(&:to_s)
          input.each do | row |
            output << row.dup
          end
        else
          # ??? Use Metatable?
          cols = [ :__META__ ] + input.header.map(&:to_sym) #  @meta_columns
          header = Header.new(cols)
          header.each{|c| c.meta.type = ::String}
          output = Table.new([], header)
          output << header.map(&:to_s)
          @meta_columns.each do | mc |
            row = [ mc.to_s ] + input.header.map do |c|
              c.meta.send(mc).to_s
            end
            output << row
          end
          input.each do | row |
            output << row.to_a.map(&:to_s).unshift('')
          end
        end
        output
      end
    end
  end
end

