require 'cx'
require 'yaml'

module CX
  class CommandFactory
    include Support
    
    def initialize
      @by_name = {}
    end

    def call args
      raise TypeError, "unspected #{x.class}" unless Args === args
      cmd_name = args.args.shift.to_sym
      unless cmd = @by_name[cmd_name]
        raise ArgumentError, "cannot find xform for #{cmd_name.inspect} : valid commands : #{valid_commands.inspect}"
      end
      cls = cmd.cls
      obj = cls.new
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
      commands.each do | cls, info |
        info[:class_name] = cls
        vals = info.values_at(*CommandDesc.members)
        cmd = CommandDesc.new(*vals)
        register! cmd
      end
      self
    end

    def register! cmd
      register_name! cmd, cmd.name
      cmd.aliases.map!(&:to_sym)
      cmd.aliases.each{|a| register_name! cmd, a}
    end
    
    def register_name! cmd, name
      name = name.to_sym
      existing = @by_name[name]
      if existing && existing != cmd
        raise_ "#{cmd.class_name} : #{name} already exists: #{existing.class_name}"
      end
      # pp(name: name, cmd: cmd.name)
      @by_name[name] = cmd
    end

    def build_index!
      YamlGenerator.new.run!
    end
    
    COMMANDS_YML = File.expand_path("../commands.yml", __FILE__)

    ###########################################
    
    class CommandDesc < Struct.new(:class_name, :name, :aliases, :synopsis, :description, :suffixes, :arguments, :options, :file, :path)
      include Support
      def initialize *args
        super
        self.name ||= infer_name(class_name)
        self.class_name = class_name.to_sym
        self.aliases ||= ""
        self.synopsis ||= "NO-SYNOPSIS"
        self.description ||= "NO-DESCRIPTION"
        self.suffixes ||= [ ]
        self.arguments ||= ['...']
        self.options ||= { }
        self.file or raise ArgumentError, "file"
        self.path or raise ArgumentError, "path"
        unless Array === self.aliases
          self.aliases = self.aliases.strip.split(/\s*,\s*/, -1)
        end
        name.to_s.sub(/^(.+)-in$/ ){|m| self.aliases.unshift "-#{$1}"}
        name.to_s.sub(/^(.+)-out$/){|m| self.aliases.unshift "#{$1}-"}
        self.aliases = self.aliases.map(&:to_sym).uniq
        self
      rescue => exc
        raise_  "#{exc.message} : #{args.inspect}", exc
      end         

      def infer_name class_name
        class_name.to_s.gsub(/([a-z])([A-Z])/){|m| "#{$1}-#{$2}"}.downcase.to_sym
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
    
    class YamlGenerator
      attr_accessor :verbose
      
      def run!
        yaml = [ ]
        Dir.glob('lib/cx/xform/**.rb').sort.each do |file|
          yaml << scan!(file)
        end
        yaml = yaml * "\n" + "\n\n"
        if verbose
          puts "yaml ::::"
          lineno = 0
          yaml.split(/\n/, -1) do | line |
            puts '%-3d %s' % [lineno += 1, line]
          end
          puts "::::"
        end
        CommandFactory.new.load!(yaml) # Verify before write.
        File.write(COMMANDS_YML, yaml)
      end
      
      def scan! file
        block = lines = nil
        emit_block = lambda do | |
          if block
            lines = (lines || []) + block
            lines << "  file: #{file.inspect}"
            lines << "  path: #{file.gsub(%r{^lib/|\.rb$}, '').inspect}"
          end
        end
        File.readlines(file).each do | line |
          case line
          when /^\s*# :COMMAND:/
            emit_block[]
            block = [ ]
          when /^\s*# (.*)/
            block << $1 if block
          else
            emit_block[]
            block = nil
          end
        end
        emit_block[]
        lines || []
      end
    end
  end
end
