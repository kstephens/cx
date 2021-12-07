# frozen_string_literal: true

require 'cx/xform'
require 'fileutils'
require 'cx/random'

# :COMMAND:
# Help:
#   aliases:
#   synopsis: 'This documentation.'
#   args: [ command ]

module CX
  module Xform
    class Help
      include Xform

      attr_reader :factory
      
      def call input, env
        require 'cx/command_factory'
        @factory = CommandFactory.new.load!
        run_examples! if opts[:run_examples]
        make_help! if opts[:make_help]
        help!
      end        

      def help_file
        "#{CX.base_dir}/doc/help.md"
      end

      def help!
        unless help = (File.read(help_file) rescue nil)
          help = help_doc!
          File.write(help_file, help)
        end
        Table.new([[help]], Header.new([:HELP]))
      end

      def make_help!
        File.unlink(help_file) rescue nil
      end

      attr_reader :doc
      def help_doc!
        @doc = String.new
        doc << <<'END'
# Overview

CX processes a pipeline of commands which transform tabular data.

A pipeline's commands are separated by "`//`" -- mnemonic: Unix shell pipe "`|`".

Some commands have pipelines arguments delimited by "`{{`" and "`}}`".

# Commands

## Options

Command and global options:

   Syntax         | Semantic 
------------------|--------------------------------
`--FLAG`          | Enable.
`--no-FLAG`       | Disable (false).
`--OPTION=VALUE`  | Sets option.
`--`              | Terminates all option parsing.

## Arguments

Most commands take one or more column arguments:

    Syntax              | Semantic
------------------------|--------------------------------
`COLUMN`                | Name or index.
`COLUMN:-`              | Reverse order or removal.
`COLUMN:+`              | Forward order or addition.
`COLUMN:!`              | Negation.
`COLUMN:arg1;arg2...`   | Processing arguments.
`COLUMN:opt1=val1;...`  | Processing options.

For most commands, all columns are processed when column arguments are given.

The column name  `"*"` implies all columns; see `cut` for examples.

# Global Options

  Syntax            | Semantic
--------------------|-------------------------
`--debug`           | Enable debugging info.
`--verbose`         | Enable verbose info.  
`--help`            | Print this document.    

END

        doc << "# Example Data\n\n"
        Dir["#{CX.base_dir}/ex/data/*.*"].sort.each do | file |
          code_block do
            doc << " $ cat #{File.basename file} \n"
            doc << File.read(file)
          end
          doc << "\n"
        end

        doc << "# Commands\n\n"
        commands.each do | c |
          doc << "## `#{c.name}`\n\n"
          doc << c.synopsis << "\n"
          doc << "\nAliases: " << c.aliases.map{|x| code x}.join(', ') << ".\n" unless c.aliases.empty?

          doc << "\nInvocation: \n\n"
          doc << "`#{c.name}` "
          doc << '*column-args* *...* ' if c.has_column_args?
          unless c.options.empty?
            doc << '*[* '
            c.options.each do |o|
              doc << code(o.brief) << ' '
            end
            doc << '*]* '
          end
          doc << c.arguments.map{|n| code(n)} * ' '
          doc << '*[* `{{` *pipeline* `}}` *...* ' if c.has_pipeline_args?
          doc << "\n"

          unless c.options.empty?
            doc << "\nOptions:\n\n"
            c.options.each do | o |
              doc << "* " << code(o.brief) << ' - ' << o.description << "\n"
            end
          end

          doc << "\n" << c.description << "\n" unless c.description.empty?

          unless c.example_runs.empty?
            doc << "\nExamples:\n\n"
            c.example_runs.each do | e |
              c.read_example!(e)
              doc << "```\n"
              doc << " $ #{e[:cmd]} \n"
              doc << e[:files]['actual']
              doc << "```\n\n"
            end
          end

          doc << "\n"
        end

        doc << <<'END'

# Installation

```
git clone https://github.com/kstephens/cx.git
gem install cx
```

# Attribution

Copyright 2020 - Kurt Stephens 

END
        doc
      end

      def code x
        '`' + x.to_s + '`'
      end

      def code_block x = nil
        doc << "\n```\n"
        block_given? ? yield : (doc << x)
        doc << "\n```\n"
      end

      def commands
        factory.all.sort_by(&:name)
      end

      #######################################

      def run_examples!
        commands.each do | cmd |
          log.info "  ### #{cmd.name} BEGIN #################################################"
          cmd.example_runs.each do | ex |
            log.info "    ----------------------------------------------------"
            run_example! cmd, ex
            log.info "    ----------------------------------------------------\n"
          end
          log.info "  ### #{cmd.name} END   ##################################################\n"
        end
      end

      def run_example! command, e
        # pp(example: e)
        dir, cmd = e.values_at(:dir, :cmd)
        log.info "run #{command.name} : #{cmd}"
        log.info "dir #{dir}"
        FileUtils.mkdir_p(dir)
        File.write("#{dir}/cmd", cmd)
        File.write(run = "#{dir}/run", <<"END")
#!/usr/bin/env bash
dir='#{dir}'
cp -p ex/data/*.* "$dir"
export CX_RANDOM_SEED=#{CX::Random.seed}
PATH="$(/bin/pwd)/bin:$PATH"
cd "$dir" || exit 9
[[ -n "$CX_VERBOSE" ]] && set -x
(
  #{cmd}
) >actual
echo $! > exit
[[ -f expected ]] || cp actual expected
diff -u expected actual | (read _; read _; cat) > diff
[[ ! -s diff ]]
END
        File.chmod(0755, run)
        e[:success] = system run
        command.read_example! e
        ok =  e[:success]
        log.info "run #{command.name} : #{cmd} : ok #{ok}"
        log.info "actual: ::::\n#{e[:files]['actual']}\n::::"
        log.info "output: ::::\n#{e[:files]['output']}\n::::"
      end
    end
  end
end
