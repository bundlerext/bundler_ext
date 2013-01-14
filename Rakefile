#!/usr/bin/env rake
begin
  require 'rspec/core/rake_task'
  require 'bundler'
rescue LoadError
  puts "Please install runtime and development dependencies to run tasks"
end

Bundler::GemHelper.install_tasks

RSpec::Core::RakeTask.new('spec')

desc "Run specs"
task :default => :spec
