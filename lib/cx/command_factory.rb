require 'cx'
require 'cx/logging'
require 'yaml'

module CX
  class CommandFactory
    def initialize
      @by_name = {}
    end

    def call argv
      argv = argv.dup
      cmd_name = argv.shift.to_sym
      cmd = @by_name[cmd_name]
      cls = cmd.cls
      obj = cls.new(argv)
      obj
    end
    alias :new :call

    def load! contents = nil
      contents ||= File.read(COMMANDS_YML)
      data = YAML.load(contents, symbolize_names: true)
      data.each do | cls, info |
        info[:class_name] = cls
        vals = info.values_at(*CommandDesc.members)
        desc = CommandDesc.new(*vals)
        @by_name[desc.name] = desc
        desc.aliases.each{|a| @by_name[a] = desc}
      end
      self
    end
    
    def build_index!
      YamlGenerator.new.run!
    end
    

    COMMANDS_YML = File.expand_path("../commands.yml", __FILE__)

    class CommandDesc < Struct.new(:class_name, :name, :aliases, :synopsis, :description, :arguments, :options, :file, :path)
      include Logging
      def initialize *args
        super
        self.name ||= infer_name(class_name)
        self.class_name = class_name.to_sym
        self.aliases ||= ""
        self.synopsis ||= "NO-SYNOPSIS"
        self.description ||= "NO-DESCRIPTION"
        self.arguments ||= ['...']
        self.options ||= { }
        self.file or raise ArgumentError, "file"
        self.path or raise ArgumentError, "path"
        unless Array === self.aliases
          self.aliases = self.aliases.strip.split(/\s*,\s*/, -1)
        end
        name.to_s.sub(/$(.+)-in$/ ){|m| self.aliases << "-#{$1}"}
        name.to_s.sub(/$(.+)-out$/){|m| self.aliases << "#{$1}-"}
        self.aliases = self.aliases.map(&:to_sym).sort.uniq
        self
      rescue => exc
        raise_  "#{exc.message} : #{args.inspect}", exc
      end         

      def infer_name class_name
        class_name.to_s.gsub(/([a-z])([A-Z])/){|m| "#{$1}-#{$2}"}.downcase
      end
      
      def cls
        unless @cls
          require path
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
