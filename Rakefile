require 'rubygems'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = %w(--no-colour --format progress)
end

namespace :spec do
  desc 'Run RSpec code examples in specdoc mode'
  RSpec::Core::RakeTask.new(:doc) do |t|
    t.rspec_opts = %w(--backtrace --colour --format doc)
  end

  desc 'Run RSpec code examples with rcov'
  RSpec::Core::RakeTask.new(:rcov) do |t|
    t.rcov = true
    t.rcov_opts = %w(--text-report --exclude /gems/,/Library/,/usr/,.bundle,spec)
    t.rspec_opts = %w(--no-colour --format progress)
  end
end

task :default => [:spec]
