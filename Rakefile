require "bundler/gem_tasks"

require 'rspec/core'
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = 'spec/**{,/*/**}/*_spec.rb'
end
task :default => :spec

desc 'Open an irb session preloaded with the gem library'
task :console do
    sh 'irb -rubygems -I lib -r sql-maker'
end
task :c => :console
