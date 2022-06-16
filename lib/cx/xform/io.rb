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
        env[:in_file] = env[:out_file] = nil
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
          env[mode =~ /r/ ? :in_file : :out_file] = file_name
          case 
          when mode =~ /w/ && file_name !~ %r{^/dev/}
            open_tempfile(file_name, mode) do | ioh |
              yield ioh
            end
          else
            File.open(file_name, mode) do | ioh |
              yield ioh
            end
          end
        else
          raise_ TypeError, "cannot open #{io.inspect} #{mode.inspect}"
        end
      end

      def update_stats! env, direction, file_name, n_bytes
        env = env[:main]
        (env[:trace][direction][:files] ||= []) << file_name
        env[:stats][direction][:files] += 1
        env[:stats][direction][:bytes] += n_bytes if n_bytes
      rescue
      end

      def open_tempfile file_name, mode
        tmp = nil
        begin
          tmp = Tempfile.new(File.basename(file_name) + '.tmp.', File.dirname(file_name))
          yield tmp
        ensure
          tmp.close
          File.chmod(0666 & ~ File.umask, tmp.path) # TODO: use current mask.
          File.rename(tmp.path, file_name)
        end
      ensure
        File.unlink(tmp.path) rescue nil
      end
    end

    class IoIn
      include IoBase
      def call input, env
        open(@io, "r", env) do | ioh |
          header = Header.new([:_INPUT_]).each{|c| c.meta.type = ::String}
          input_string = ioh.read
          update_stats! env, :in, env[:in_file], input_string.size
          Table.new([[input_string]], header)
        end
      end
      def default_io ; $stdin ; end
    end
    
    class IoOut
      include IoBase
      def call input, env
        mode = opts.fetch(:mode, "w")
        open(@io, mode, env) do | ioh |
          # io.write("=== BEGIN ===========================\n")
          @n_bytes = 0
          log.info { "#{self} input dims = #{input.dimensions}" }
          input.each do | r |
            __write_row! r, ioh
          end
          update_stats! env, :out, env[:out_file], @n_bytes
          # io.write("=== END   ===========================\n\n")
        end
        input
      end
      def default_io ; $stdout ; end
      # ??? WTF: calling for each row drastically speed things up!
      def __write_row! r, ioh
        r.each do | _c, v |
          v = v.to_s
          @n_bytes += v.size
          ioh.write(v)
        end
      end
    end
  end
end

