require 'cx'
require 'cx/struct'
require 'digest/md5'
require 'fileutils'
require 'yaml'

module CX
  class Example < Struct.new(:command, :example, :success, :files, :contents, :dir, :dir_name, :base_dir, :yaml_file)
    include Support, StructSupport

    def self.yaml_file_for_dir dir ; "#{dir}/example.yml" ; end
    
    def initialize *args
      super
      self.base_dir   ||= 'ex/cmd'
      raise "no base_dir" unless base_dir
      self.dir_name   ||= example && Digest::MD5.hexdigest(example)
      self.dir        ||= "#{base_dir}/#{command}/#{dir_name}"
      self.yaml_file  ||= self.class.yaml_file_for_dir(dir)
      self.files      ||= Contents.new.set_dir!(dir)
    end

    class Contents < Struct.new(:run, :exit, :output, :expected, :actual, :diff)
      include Support, StructSupport

      def set_dir! dir
        from_hash!(members_map{|name, _| "#{dir}/#{name}"})
        self
      end
      
      def read
        self.class.new_from_map{|file| File.read(self[file]) rescue nil}
      end

      def show!
        self.class.members.each do | n |
          log.info "%-12s : %s" % [n, with_newlines(self[n])]
        end
        self
      end
    end

    def contents
      @contents ||= files.read
    end

    def accept_command
      "mv #{files.actual} #{files.expected}"
    end

    def show!
      self.class.members.each do | n |
        log.info "%-12s : %s" % [n, with_newlines(self[n])]
      end
      self
    end
    
    def save!
      log.info "Saved #{yaml_file}"
      File.write(yaml_file, YAML.dump(self))
    end

    def self.load! dir
      YAML.load(File.read(yaml_file_for_dir dir))
    end
    
    def run!
      log.info "run #{command} : #{example}"
      log.info "dir #{dir}"
      FileUtils.mkdir_p(dir)
      File.write(files.run, <<"END")
#!/usr/bin/env bash
dir='#{dir}'
cp -p ex/data/*.* "$dir"
export CX_RANDOM_SEED=#{CX::Random.seed}
PATH="$(/bin/pwd)/bin:$PATH"
cd "$dir" || exit 9
[[ -n "$CX_VERBOSE" ]] && set -x
(
  #{example};
  echo $! > exit
) >actual
[[ -f expected ]] || cp actual expected
diff -u expected actual | (read _; read _; cat) > diff
[[ ! -s diff ]]
END
      File.chmod(0755, files.run)
      self.success = system("#{files.run} </dev/null")
      save!
      self
    end
    
    def self.examples_with_diffs
      base_dir = "ex/cmd"
      Dir["#{base_dir}/*/*/diff"].sort.map do | diff |
        dir = File.dirname(diff)
        ex = CX::Example.load!(dir)
        # ex.show!
        # $stderr.puts pps(ex: ex.files, contents: ex.contents)
        # pp(files: ex.files, contents: ex.contents)
        ex.contents.diff.empty? ? nil : ex
      end.compact
    end
    
    def self.diffs!
      extend Logging
      CX::Logging.log.level = ::Logger::INFO
      examples = examples_with_diffs
      # pp(examples: examples)
      log.info "  ### { diffs!"
      examples.each do | ex |
        log.info "    ### { #{ex.command} : #{ex.example}"
        # pp(files: ex.files, contents: ex.contents)
        ex.contents
        ex.show!
        s = <<"END"
  ### to accept actual:
  #{ex.accept_command}
END
        $stderr.puts s
        log.info "    ### } #{ex.command} : #{ex.example}"
      end
      
      log.info "    ### { accept #######################################"
      examples.each do | ex |
        $stderr.puts "#{ex.accept_command}  # #{e.command} : #{e.example}"
      end
      log.info "    ### } accept #######################################"
      log.info "  ### } diffs!"

    end
  end
end

