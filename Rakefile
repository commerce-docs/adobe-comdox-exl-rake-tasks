# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rake/testtask'

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

desc 'Run tests'
task default: :test

desc 'Build the gem'
task :build do
  sh 'gem build adobe-comdox-exl-rake-tasks.gemspec'
end

desc 'Install the gem locally'
task install: :build do
  sh 'gem install ./adobe-comdox-exl-rake-tasks-0.1.0.gem'
end

desc 'Uninstall the gem locally'
task :uninstall do
  sh 'gem uninstall adobe-comdox-exl-rake-tasks'
end

desc 'Clean build artifacts'
task :clean do
  rm_f FileList['*.gem']
  rm_rf 'pkg/'
  rm_rf 'tmp/'
end
