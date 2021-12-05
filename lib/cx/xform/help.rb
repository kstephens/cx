# frozen_string_literal: true

require 'cx/xform'

# :COMMAND:
# Help:
#   aliases:
#   synopsis: 'This documentation.'
#   args: [ command ]

module CX
  module Xform
    class Help
      include Xform
      
      def call input, env
        require 'cx/command_factory'
        factory = CommandFactory.new.load!
        _doc = String.new
        
        doc = String.new
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

## Examples

```
# Match all rows where field `"a"` does not contain `"foo"`.
cx in file.csv // grep a:!foo
```

# Global Options

  Syntax            | Semantic
--------------------|-------------------------
`--debug`           | Enable debugging info.
`--verbose`         | Enable verbose info.  
`--help`            | Print this document.    

END

        doc << "# Commands\n"
        factory.all.
          sort_by(&:name).
          # take(17).
          #take(14).
          #reverse.take(1).
          each do | c |
          doc << "\n"
          doc << "## `#{c.name}`\n\n"
          doc << c.synopsis
          doc << "\n\nAliases: " << c.aliases.map{|x| code x}.join(', ') << ".\n" unless c.aliases.empty?

          unless c.options.empty?
            doc << "\n\nOptions:\n\n"
            c.options.each do | name, desc |
              doc << "* " << code('--' + name.to_s) << " - " << desc.to_s << "\n"
            end
          end

          doc << "\n\n" << c.description unless c.description.empty?
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
        Table.new([[ doc ]], Header.new([:DOC]))
      end

      def code x
        '`' + x.to_s + '`'
      end
    end
  end
end
