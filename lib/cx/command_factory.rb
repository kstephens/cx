require 'cx'
require 'yaml'
require 'digest/md5'
require 'fileutils'

module CX
  class CommandFactory
    include Support

    attr_reader :all, :by_name
    
    def initialize
      @all = [ ]
      @by_name = {}
    end

    def call args
      raise TypeError, "unexpected #{x.class}" unless Args === args
      cmd_name = args.args.shift
      raise TypeError, cmd_name unless String === cmd_name
      unless cmd = @by_name[cmd_name]
        raise ArgumentError, "unknown command  #{cmd_name.inspect} : valid commands : #{valid_commands.inspect}"
      end
      cls = cmd.cls
      obj = cls.new
      obj.progname = cmd_name.to_s
      obj.set_args! args
      obj
    end
    alias :new :call

    def valid_commands
      @by_name.keys.map(&:to_s).uniq
    end
    
    def load! contents = nil
      contents ||= File.read(COMMANDS_YML)
      load_commands! YAML.load(contents, symbolize_names: true)
      self
    end

    def load_commands! commands
      commands.each do | cmd |
        register! cmd
      end
      self
    end

    def register! cmd
      register_name! cmd, cmd.name
      @all << cmd
      @all.sort_by!(&:name)
      cmd.aliases
      cmd.aliases.each{|a| register_name! cmd, a}
    end
    
    def register_name! cmd, name
      raise TypeError, "name #{name.inspect}" unless String === name
      existing = @by_name[name]
      if existing && existing != cmd
        raise_ "#{cmd.class_name} : #{name.inspect} in #{cmd.file} : already exists as #{existing.class_name.inspect} #{existing.file}"
      end
      @by_name[name] = cmd
    end

    def build_index!
      YamlGenerator.new.run!
    end
    
    COMMANDS_YML = File.expand_path("../commands.yml", __FILE__)

    ###########################################
    
    class CommandDesc < Struct.new(
      :class_name, :name, :aliases, :synopsis, :description,
      :suffixes, :arguments, :options,
      :has_column_args, :has_pipeline_args,
      :examples,
      :file, :lineno, :path)
      include Support

      class Option < Struct.new(:name, :description, :default, :values)
        def initialize *args
          super

          if (n = name.to_s).sub!(/=(.+)$/, '')
            self.values ||= $1
          end
          self.name = n.to_sym
          
          if /Default:\s*(.+)/.match?(description)
            self.default ||= $1.strip
          end
          self.values = values.split(/,/) if String === values
          self.values ||= [ ]
        end
        
        def self.from_hash h
          new(*h.values_at(*members))
        end
        
        def brief
          case
          when self.default || ! self.values.empty?
            "--#{name}=..."
          else
            "--#{name}"
          end
        end
      end
      
      def self.from_hash h
        new(*h.values_at(*CommandDesc.members))
      end
      
      def initialize!
        self.file or raise ArgumentError, "file"
        self.path or raise ArgumentError, "path"

        raise_ TypeError, "class_name #{class_name.inspect}" unless String === class_name
        self.name ||= infer_name(class_name)

        raise_ TypeError, "name #{name.inspect}" unless String === name
        
        self.aliases ||= ""
        self.synopsis ||= ""
        self.description ||= ""
        self.suffixes ||= [ ]
        self.arguments ||= [ ]
        self.options ||= { }
        self.examples ||= [ ]
        
        if Hash === options
          self.options = options.map do | (name, desc) |
            Option.new(name, desc)
          end
        end
        
        unless Array === self.aliases
          self.aliases = self.aliases.split(/\s*,\s*/).map(&:strip)
        end
        unless Array === self.examples
          self.examples = self.examples.split(/\s*\n\s*\n\s*/, -1).map(&:strip)
        end
        
        name.to_s.sub(/^(.+)-in$/ ){|m| self.aliases.unshift "-#{$1}"}
        name.to_s.sub(/^(.+)-out$/){|m| self.aliases.unshift "#{$1}-"}
        self.aliases = self.aliases.uniq
        self
      rescue => exc
        raise_  "#{exc.message} : #{args.inspect}", exc
      end

      def read_example! e
        e[:files] ||= { }
        Dir["#{e[:dir]}/*"].sort.each do | f |
          e[:files][File.basename(f)] = (File.read(f) rescue nil)
        end
        e
      end
      
      def infer_name class_name
        class_name.to_s.gsub(/([a-z])([A-Z])/){|m| "#{$1}-#{$2}"}.downcase
      end

      def has_column_args?
        self.has_column_args ||= Xform::SelectColumns === cls
      end

      def has_pipeline_args?
        self.has_pipeline_args ||= Xform::PipelineArgs === cls
      end

      def cls
        unless @cls
          unless @cls = (CX::Xform.const_get(class_name) rescue nil)
            log.debug "#{self.class} : load #{class_name.inspect} : require #{path.inspect}"
            require path
          end
          @cls = CX::Xform.const_get(class_name)
        end
        @cls
      end
    end

    require 'pry'
    
    class YamlGenerator
      include Support
      
      def run!
        commands = [ ]
        Dir.glob('lib/cx/xform/**.rb').sort.each do |file|
          scan_blocks!(file) do | block |
            commands << parse_block!(block)
          end
        end
        yaml = YAML.dump(commands)
        factory = CommandFactory.new.load!(yaml)
        log.info "Parsed #{COMMANDS_YML} #{factory.all.size} commands"
        File.write(COMMANDS_YML, yaml)
        log.info "Wrote #{COMMANDS_YML} #{File.size(COMMANDS_YML)} bytes"
      end

      def parse_block! block
        data =
        begin
          YAML.load(block, symbolize_names: true)
        rescue => e
          log.error e.inspect
          log.error "YAML block ::::\n#{block}\n::::"
          raise e
        end
        class_name = data.keys.first.to_s
        info = data.values.first
        info[:class_name] = class_name
        info[:options]   ||= info[:opts] # ???
        info[:arguments] ||= info[:args] # ???
        command = CommandDesc.from_hash(info).initialize!
        log.info "#{self.class} : #{command.file}:#{command.lineno} : found #{command.class_name} : #{command.name} : #{command.aliases}"
        command
      end
      
      def scan_blocks! file, &blk
        block = block_lineno = nil
        lineno = 0
        emit = lambda do | |
          if block
            block << "  file: #{file.inspect}"
            block << "  lineno: #{block_lineno}"
            block << "  path: #{file.gsub(%r{^lib/|\.rb$}, '').inspect}"
            blk.call(block * "\n" + "\n\n")
            block = nil
          end
        end
        File.readlines(file).each do | line |
          lineno += 1
          case line
          when /^\s*# :COMMAND:/
            emit[]
            block = [ ]
            block_lineno = lineno
          when /^\s*# (.*)/
            block << $1 if block
          else
            emit[]
          end
        end
        emit[]
        self
      end
    end
  end
end
