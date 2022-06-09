require 'cx'
require 'cx/example'
require 'cx/command_factory'
require 'fileutils'
require 'erb'

module CX
  class Help
    include Support
    
    attr_accessor :factory

    def factory
      @factory ||= CommandFactory.new.load!
    end
    
    def commands
      @commands ||= factory.all
    end

    def help_file
      "#{CX.lib_dir}/cx/doc/help.md"
    end

    def document
      unless @document ||= (File.read(help_file) rescue nil)
        make_document!
      end
      @document
    end

    def make_document!
      File.unlink(help_file) rescue nil
      @document = make_document
      File.write(help_file, @document)
      log.info "wrote help_file : #{help_file} : #{@document.size} bytes"
      self
    end

    def help_md_erb
      "#{help_file}.erb"
    end
    
    def make_document
      require 'terminal-table'
      
      commands.each do | c |
        c.examples.map! do | example |
          e = Example.load!(command: c.name, example: example)
          # log.info "Loaded example: #{e.to_h.inspect}"
          # log.info "Loaded example content:"
          # e.contents.log_members
          e
        end
        log.info "LOADED : command #{c.name} : #{c.options.size} options : #{c.examples.size} examples"
      end

      template = File.read(help_md_erb)
      # compiler = ERB::Compiler.new('<>')
      # code, enc = compiler.compile(md_erb)
      # File.write("tmp/help.md.rb", code)
      # puts code; exit!
      erb = ERB.new(template, "<>")
      erb.filename = help_md_erb
      doc = erb.result(binding)

      doc.gsub!(/(\s*\\\n)+/, '')
      doc.gsub!(/\n\n+/, "\n\n")

      doc
    end

    def command_option_table c
      rows = c.options.map{|o| [ code(o.brief), br(o.description), o.default, o.values * ', ' ]}
      t = ::Terminal::Table.new do | t |
        t.headings = %w(Options Description Default Values)
        t.style = { border_i: '|', border_x: '-', border_top: false, border_bottom: false }
        t.rows = rows
      end
      t = t.to_s.gsub(/^\|/, '')
      t
    end

    def code x
      no_wrap "<code>#{x}</code>"
    end

    def no_wrap x
      x.gsub(' ', '&nbsp;')
    end

    def br x
      x.to_s.gsub(/\n/, '<br />')
    end
    
    def run_examples!
      Example::Runner.new.run!
    end

  end
end

