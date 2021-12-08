require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

task :default => [ :commands_yml, :spec, :js_test, :readme ]

task :build => [ :commands_yml, :'examples:run', :readme ]

desc "Run tests under simplecov."
task :coverage do
  ENV['COVERAGE'] = '1'
  Rake::Task[:spec].invoke
end

task :readme do
  sh "bin/cx --debug help make-help show > tmp/README.md"
  sh "sed -E -e 's@<[a-z]+[^>]+>|</[a-z]+>@@g' tmp/README.md > README.md"
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

namespace :examples do
  desc "run examples."
  task :run => [ :commands_yml ] do
    sh "bin/cx --debug help run-examples"
  end
  desc "Show diff of expected vs. actual."
  task :diff do
    require 'cx/example'
    CX::Example.diffs!
  end
end
  
desc "Generate lib/cx/commands.yml"
XFORM_FILES = Rake::FileList.new("lib/cx/xform/*.rb")
task :commands_yml => "lib/cx/commands.yml"
file "lib/cx/commands.yml" => XFORM_FILES + [ 'Rakefile', 'lib/cx/command_factory.rb' ] do
  require 'cx/command_factory'
  CX::Logging.log.level = ::Logger::DEBUG
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

