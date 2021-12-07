require 'cx'
require 'cx/struct'
require 'digest/md5'
require 'fileutils'
require 'yaml'

module CX
  class Example < Struct.new(:command, :example, :success, :files, :contents, :dir, :dir_name, :base_dir, :yaml_file)
    include Support, StructSupport

    def self.yaml_file_for_dir dir ; "#{dir}/example.yml" ; end
    BASE_DIR = 'ex/cmd'
    
    def initialize *args
      super
      self.base_dir   ||= BASE_DIR
      self.dir_name   ||= example && Digest::MD5.hexdigest(example)
      self.dir        ||= "#{base_dir}/#{command}/#{dir_name}"
      self.yaml_file  ||= self.class.yaml_file_for_dir(dir)
      self.files      ||= Files.new.set_dir!(dir)
    end

    class Files < Struct.new(:run, :exit, :output, :expected, :actual, :diff)
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

    def self.load! opts
      e = new_from_hash(opts)
      YAML.load(File.read(e.yaml_file))
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
      Dir["#{BASE_DIR}/*/*/diff"].sort.map do | diff |
        dir = File.dirname(diff)
        ex = CX::Example.load!(dir: dir)
        ex.contents.diff.empty? ? nil : ex
      end.compact
    end

    class Runner
      include Support
      
      attr_accessor :commands, :factory

      def factory
        @factory ||= CommandFactory.new.load!
      end

      def commands
        @commands ||= factory.all.sort_by(&:name)
      end

      def run!
        commands.each do | cmd |
          log.delimited "command : #{cmd.name} ================== " do 
            cmd.examples.each do | example |
              log.delimited "example : #{example}" do 
                run_example! cmd, example
              end
            end
          end
        end
      end

      def run_example! command, example
        example = Example.new_from_hash(
          command:    command.name,
          example:    example,
        )
        example.run!
        example.show!
      end
    end
    
    def self.diffs!
      extend Logging
      CX::Logging.log.level = ::Logger::INFO
      examples = examples_with_diffs
      log.delimited "diffs!" do
        examples.each do | ex |
          log.delimited "#{ex.command} : #{ex.example}" do
            ex.contents
            ex.show!
            s = <<"END"
  ### to accept actual:
  #{ex.accept_command}
END
            $stderr.puts s
          end
        end
      end
      
      log.info "diffs #{examples.size}"
      unless examples.empty?
        log.delimited "accept" do
          examples.each do | ex |
            $stderr.puts "#{ex.accept_command}  # #{e.command} : #{e.example}"
          end
        end
      end
    end
  end
end

