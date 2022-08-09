require 'cx'
require 'cx/struct'
require 'digest/md5'
require 'fileutils'
require 'shellwords'
require 'pathname'
require 'yaml'
require 'digest/md5'

module CX
  class Example < Struct.new(:command, :example, :example_md5, :exit_code, :success, :files, :data_files, :contents, :dir, :dir_name, :base_dir, :yaml_file)
    include Support, StructSupport

    def self.yaml_file_for_dir dir ; "#{dir}/example.yml" ; end
    BASE_DIR = 'ex/cmd'
    
    def initialize *args
      super
      self.base_dir   ||= BASE_DIR
      self.example_md5 ||= example && Digest::MD5.hexdigest(example)
      self.dir_name   ||= example_md5
      self.dir        ||= "#{base_dir}/#{command}/#{dir_name}"
      self.yaml_file  ||= self.class.yaml_file_for_dir(dir)
      self.files      ||= Files.new.set_dir!(dir)
      self.data_files ||= data_files_available.map{|p| p.basename.to_s}.select{|p| self.example.to_s.index(p)}
    end

    def self.data_files_pattern
      "ex/data/*.*"
    end

    def self.data_files_available
      Dir[data_files_pattern].sort.map{|s| Pathname.new(s)}
    end

    def data_files_available ; Example.data_files_available ; end

    class Files < Struct.new(:run, :stderr, :expected, :actual, :diff)
      include Support, StructSupport

      def set_dir! dir
        from_hash!(members_map{|name, _| "#{dir}/#{name}"})
        self
      end
      
      def read
        self.class.new_from_map{|file| File.read(self[file]) rescue nil}
      end
    end

    def contents
      @contents ||= files.read
    end
    
    def read!
      @contents = files.read
      self
    end

    def accept_command
      "mv #{files.actual} #{files.expected}"
    end

    def save!
      log.info "Saved #{yaml_file}"
      File.write(yaml_file, YAML.dump(self))
    end

    def self.load! opts
      e = new_from_hash(opts)
      e = YAML_load(File.read(e.yaml_file))
      # Logging.log.info "#{opts.inspect} Loaded: #{e.inspect}"
      e
    end

    def self.YAML_load(data, **opts)
      YAML.safe_load(data,
        **opts,
        permitted_classes: [
          Example,
          Files,
          #CommandDesc,
          #CommandDesc::Option,
          OpenStruct,
          Symbol,
          Pathname,
        ]
      )
    end

    def write_files!
      FileUtils.mkdir_p(dir)
      File.write(files.run, <<"END")
#!/usr/bin/env bash
dir='#{dir}'
cp -p #{Example.data_files_pattern} "$dir"
export CX_RANDOM_SEED=#{CX::Random.seed}
PATH="$(/bin/pwd)/bin:$PATH"
cd "$dir" || exit 9
[[ -n "$CX_EX_VERBOSE" ]] && set -x
#{example} 2> stderr > actual
echo $! > exit_code
[[ -f expected ]] || cp actual expected
diff -u expected actual | (read _; read _; cat) > diff
[[ ! -s diff ]]
END
      File.chmod(0755, files.run)
    end
    
    def run!
      argv = Shellwords.split(example)
      # pp(argv: argv)
      raise "Unexpected example arg list : #{argv.inspect}" unless argv.shift == 'cx'
      argv = Shellwords.shellsplit(ENV['CX_EX_OPTS'] || '') + argv
      write_files!
      main = CX::Main.new(argv)
      log.delimited "RUNNING LOCALLY" do
        log.info "run #{command} : #{example}"
        log.info "dir #{dir}"
        Example.data_files_available.map(&:to_s).each{|f| FileUtils.cp(f, dir)}
        pid = wait_status = nil
        Dir.chdir(dir) do
          pid = Process.fork do
            CX::Random.init! 1
            $stdin.reopen("/dev/null", "r")
            $stdout.reopen("actual", "w")
            $stderr.reopen("stderr", "w")
            begin
              main.run!
            ensure
              $stdout.flush rescue nil
              $stderr.flush rescue nil
            end
            exit!(main.exit_code)
          end

          log.info "pid #{pid} : waiting"
          Process.wait(pid); wait_status = $?
          log.info "pid #{pid} : finished : #{wait_status.inspect}"

          if ! File.exist?('expected')
            FileUtils.copy('actual', 'expected')
          end
          system 'diff -u expected actual | (read _; read _; cat) > diff'
        end
        Example.data_files_available.map(&:to_s).each{|f| File.unlink("#{dir}/#{File.basename(f)}")}
        
        read!
        self.success = (self.exit_code = wait_status.exitstatus) == 0
        log_members
        contents.log_members
        self.contents = nil
        save!
      end
      self
    end
    
    def self.examples_with_diffs
      Dir["#{BASE_DIR}/*/*/actual"].sort.map do | diff |
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
        @commands ||= factory.all
      end

      def run! patterns = nil
        patterns ||= [ ]
        commands = self.commands
        unless patterns.empty?
          commands = commands.select do | cmd |
            patterns.any? {|pattern| cmd.name.to_s == pattern}
          end
        end
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
        example.log_members
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
            ex.log_members
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
            $stderr.puts "#{ex.accept_command}  # #{ex.command} : #{ex.example}"
          end
        end
      end
    end
  end
end

