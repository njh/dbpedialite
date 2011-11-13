require 'rubygems'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = "spec/*.spec"
end

namespace :spec do
  desc 'Run RSpec code examples in specdoc mode'
  RSpec::Core::RakeTask.new(:doc) do |t|
    t.pattern = "spec/*.spec"
    t.rcov = false
    t.rspec_opts = %w(--backtrace --colour --format doc)
  end
  
  desc 'Run RSpec code examples with rcov'
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.pattern = "spec/*.spec"
    t.rcov = true
    t.rcov_opts = '--text-report --exclude /gems/,/Library/,/usr/,lib/tasks,.bundle,config,spec'
    t.rspec_opts = %w(--no-colour --format progress)
  end
end

task :default => [:spec]
