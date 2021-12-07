require 'fileutils'
require 'cx/example'
require 'cx/command_factory'
require 'erb'

module CX
  class Help
    attr_accessor :factory

    def factory
      @factory ||= CommandFactory.new.load!
    end
    
    def commands
      @commands ||= factory.all.sort_by(&:name)
    end

    def help_file
      "#{CX.base_dir}/doc/help.md"
    end

    def document
      unless @document
        unless @document = (File.read(help_file) rescue nil)
          make_document!
          File.write(help_file, @document)
        end
      end
      @document
    end

    def make_document!
      File.unlink(help_file) rescue nil
      @document = make_document
      self
    end

    def make_document
      md_erb = File.read(File.expand_path("../help.md.erb", __FILE__))
      compiler = ERB::Compiler.new('<>')
      code, enc = compiler.compile(md_erb)
      File.write("tmp/help.md.rb", code)
      # puts code; exit!
      erb = ERB.new(md_erb, "<>")
      doc = erb.result(binding)

      doc.gsub!(/(\s*\\\n)+/, '')
      doc.gsub!(/\n\n+/, "\n\n")

      doc
    end
      
    def code x
      "`#{x}`"
    end

    def run_examples!
      Example::Runner.new.tap{|o| o.commands = commands}.run!
    end

  end
end

