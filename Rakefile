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

