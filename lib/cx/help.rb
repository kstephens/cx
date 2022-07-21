require 'cx'
require 'cx/example'
require 'cx/command_factory'
require 'fileutils'
require 'erb'
require 'set'

module CX
  class Help
    include Support
    
    attr_accessor :opts, :search_terms, :matched_strings, :factory

    def initialize
      @opts = { }
      @search_terms = [ ]
      @matched_strings = Set.new
      yield self if block_given?
    end

    def factory
      @factory ||= CommandFactory.new.load!
    end
    
    def all_commands
      @all_commands ||= factory.all
    end

    def help_file
      "#{CX.lib_dir}/cx/doc/help.md"
    end

    def document
      case
      when search_terms.empty?
        full_document
      else
        make_document
      end
    end

    def full_document
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
      commands = all_commands.select{|c| show_command?(c)}
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
      erb = ERB.new(template, trim_mode: "<>")
      erb.filename = help_md_erb
      doc = erb.result(binding)

      doc.gsub!(/(\s*\\\n)+/, ' ')
      doc.gsub!(/\n\n+/, "\n\n")

      doc
    end

    ################################################

    def verbose?
      opts[:verbose] || search_terms.empty?
    end

    def command_table commands
      table(%w(Command Synopsis Aliases),
      commands.map do |c|
        [ c.name.to_s, c.synopsis, c.aliases * ' ']
      end)
    end

    def command_option_table c
      table(%w(Options Description Default Values),
      c.options.map do |o|
         [ code(o.brief), br(o.description), o.default, o.values * ', ' ]
      end)
    end

    def show_command_table? ; true ; end

    def show_header?
      verbose?
    end

    def show_examples?
      verbose? || opts[:examples]
    end

    def show_example_data?
      verbose? || opts[:example_data]
    end

    def show_command_detail?
      verbose?
    end

    def show_brief?
      ! opts[:verbose] || ! search_terms.empty?
    end

    def show_attribution?
      verbose?
    end

    ################################################

    def show_command? c
      command_filter.call(c)
    end

    def command_filter
      @command_filter ||=
      if search_terms.empty?
        Proc.new {|command| true }
      else
        rx = Regexp.new(search_terms.map{|term| Regexp.escape(term.downcase)} * '|')
        lambda do | command |
          matches = command_keywords(command).select{|keyword| keyword =~ rx}
          matches.empty? ? false : matched_strings
    .merge(matches)
        end
      end
    end

    def command_keywords c
      ([ c.name, c.synopsis ] +
        c.aliases + 
        c.options.map(&:brief)
      ).map!{|k| k.downcase}
    end

    ################################################

    def table headings, rows
      require 'terminal-table'
      ::Terminal::Table.new do | t |
        t.headings = headings
        t.style = { 
          border_i: '|', 
          border_x: '-', 
          border_top: false, 
          border_bottom: false,
        }
        t.rows = rows
      end.to_s.gsub(/^\|/, '').gsub(/^-+$/, '')
    end

    def code x
      no_wrap "\`#{x}\`"
    end

    def no_wrap x
      x.gsub(' ', '&nbsp;')
    end

    def br x
      x.to_s.gsub(/\n/, '<br />')
    end
    
    def run_examples! patterns = nil
      Example::Runner.new.run!(patterns)
    end

  end
end

