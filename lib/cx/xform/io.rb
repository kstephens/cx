# frozen_string_literal: true

require 'cx'
require 'cx/xform'
require 'tempfile'

# :COMMAND:
# IoIn:
#   aliases: [in, i]
#   synopsis: Read from a file.
#   args: [ filename, ... ]
#   opts: {}

# :COMMAND:
# IoOut:
#   aliases: [out, o]
#   synopsis: Write records to a file.
#   args: [ filename, ... ]
#   opts: {}

module CX
  module Xform
    module IoBase
      include Xform
      
      def initialize!
        super
        raise_ ArgumentError, "too many arguments" if args.size > 1
        @io = args[0]
      end

      def inspect_content modes
        @io.inspect
      end
      
      def open io, mode, env, &blk
        open_ io, mode, env, &blk
      rescue => exc
        raise_ exc, "cannot open #{io.inspect} #{mode.inspect}"
      end
      
      def open_ io, mode, env, &blk
        raise_ ArgumentError, "no block" unless block_given?
        case io
        when '-', nil
          open default_io, mode, env, &blk
        when IO, StringIO
          begin
            yield io
          ensure
            io.flush rescue nil
          end
        when String
          file_name = io.to_s.dup.freeze
          case mode
          when /[wa]/
            Tempfile.create(file_name) do | ioh |
              env[:out_file] = file_name
              yield ioh
            end
          else
            File.open(file_name, mode) do | ioh |
              env[:in_file] = file_name
              yield ioh
            end
          end
        else
          raise_ TypeError, "cannot open #{io.inspect} #{mode.inspect}"
        end
      end
    end

    class IoIn
      include IoBase
      def call input, env
        open(@io, "r", env) do | ioh |
          header = Header.new([:_INPUT_]).each{|c| c.meta.type = ::String}
          input_string = ioh.read
          Table.new([[input_string]], header)
        end
      end
      def default_io ; $stdin ; end
    end
    
    class IoOut
      include IoBase
      def call input, env
        open(@io, "w", env) do | ioh |
          # io.write("=== BEGIN ===========================\n")
          input.each do | r |
            r.each do | _c, v |
              ioh.write(v)
            end
          end
          # io.write("=== END   ===========================\n\n")
        end
        input
      end
      def default_io ; $stdout ; end
    end
  end
end

