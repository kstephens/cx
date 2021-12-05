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
        doc = String.new
        doc << <<'END'
= Overview

CX processes a pipeline of commands which transform tabular data.

A pipeline's commands are separated by "//" -- mnemonic: Unix shell pipe "|"
Some commands have pipelines arguments delimited by "{{" and "}}".

= Commands

== Options

Either "--FLAG" or "--NAME=VALUE". "--" terminates all option parsing.

== Arguments

Most commands take one or more column arguments to act on.
These have the form:

| COLUMN            | Name or index. |
| COLUMN:-          | Reverse order or removal. |
| COLUMN:+          | Forward order or addition. |
| COLUMN:!          | Negation. |
| COLUMN:arg1;arg2  | Processing arguments. |
| COLUMN:opt1=val1  | Processing options. 

The '*' column name implies all columns.

== Examples

```
# Match all rows where field "a" does not contain "foo".
cx in file.csv // grep a:!foo
```

= Global Options

| --debug           | Enables debugging info. |
| --verbose         | Enables verbose info.   |
| --help            | This help document.     |

END

        doc << "= Commands\n"
        factory.all.sort_by(&:name).each do | cmd |
          doc << "\n"
          doc << "== `#{cmd.name}`\n\n"
          doc << cmd.synopsis
          doc << "\n\nAliases: " << cmd.aliases.map{|x| code x}.join(', ') << ".\n" unless cmd.aliases.empty?
          unless cmd.options.empty?
            doc << "\nOptions:\n"
            cmd.options.each do | name, desc |
              doc << "* `" << name << "` - " << desc << "\n"
            end
            doc << "\n"
          end
          doc << "\n\n" << cmd.description unless cmd.description.empty?
          doc << "\n"
        end

        doc << <<'END'

= Installation

```
git clone https://github.com/kstephens/cx.git
gem install cx
```

= Attribution

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
