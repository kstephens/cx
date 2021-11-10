require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :readme do
  File.write "README.md", <<"END"
# CX

Transforms and processes columnar data as CSV, JSON, EDN, etc.

## Installation

```
gem install cx
```

## Examples

```
#{File.read("lib/cx/examples.txt")}
```

END

end

task :generate_commands_yml do
  require 'cx/command_factory'
  CX::CommandFactory::YamlGenerator.new.run!
end

task :new_class do
  file = ENV['file']
  raise if File.exist? file
  FileUtils.mkdir_p(File.dirname(file))
  File.write(file, <<'END')
# coding: utf-8
# frozen_string_literal: true
# encoding: UTF-8
# -*- coding: utf-8 -*-

require 'cx'
require 'cx/xform'

module CX
  module Xform
  end
end

END
  sh "git add '#{file}'"
  # sh "dotfiles emacs '#{file}'"
end

