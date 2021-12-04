require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => [ :readme, :commands_yml, :spec, :js_test ]

task :build => [ :readme, :commands_yml ]

desc "Run tests under simplecov."
task :coverage do
  ENV['COVERAGE'] = '1'
  Rake::Task[:spec].invoke
end

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

desc "Run JS tests"
task :js_test do
  js_files = %w[
    lib/cx/xform/html/parser_combinator.js
  ]
  js_files.each do | path |
    path = File.expand_path(path)
    sh %Q{node -e 'require("#{path}")'}
  end
end

desc "Generate lib/cx/commands.yml"
XFORM_FILES = Rake::FileList.new("lib/cx/xform/*.rb")
task :commands_yml => "lib/cx/commands.yml"
file "lib/cx/commands.yml" => XFORM_FILES do
  require 'cx/command_factory'
  CX::CommandFactory::YamlGenerator.new.run!
end

desc "Create a new lib/cx/xform/*.rb file"
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

