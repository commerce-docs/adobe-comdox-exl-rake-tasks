# MIT License
#
# Copyright (c) 2025 Adobe Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# frozen_string_literal: true

# Adobe Docs Rake Tasks
# This file contains common requires and shared functionality for Adobe documentation repositories
# Source: commerce-operations.en repository (most up-to-date)

# Common requires for all rake tasks
require 'yaml'
require 'colorator'
require 'date'
require 'json'
require 'tzinfo'

# Note: Individual namespace tasks have been moved to separate files:
# - includes.rake: Include management tasks
# - images.rake: Image management tasks  
# - whatsnew.rake: What's new tasks
# - utility.rake: Utility tasks
#
# Rake automatically loads all .rake files in this directory

# What's New Task
desc 'Generate data for a news digest.
      Default timeframe is since last update.
      For other period, use "since" argument, such as, bundle exec rake whatsnew since="jul 4"'
task :whatsnew do
  since = ENV['since']
  current_file = '_data/whats-new.yml'
  generated_file = 'tmp/whats-new.yml'
  current_data = YAML.load_file current_file
  last_update = current_data['updated']
  print 'Generating data for the What\'s New digest: $ '.magenta

  # Generate tmp/whats-new.yml
  report =
    if since.nil? || since.empty?
      `TZ='America/Chicago' bundle exec whatsup_github since '#{last_update}'`
    elsif since.is_a? String
      `TZ='America/Chicago' bundle exec whatsup_github since '#{since}'`
    else
      abort 'The "since" argument must be a string. Example: "jul 4"'
    end

  # Merge generated tmp/whats-new.yml with existing src/_data/whats-new.yml
  generated_data = YAML.load_file generated_file
  current_data['entries'] = [] if current_data['entries'].nil?
  current_data['updated'] = generated_data['updated']
  current_data['entries'].prepend(generated_data['entries']).flatten!
  current_data['entries'].uniq! { |entry| entry['link'] }

  puts "Writing updates to #{current_file}"
  File.write current_file, current_data.to_yaml

  abort report if report.include? 'MISSING whatsnew'
  puts report
end

# Utility Tasks
desc 'Render the templated files.
  Renders the templated files in the "_jekyll/templates" directory. The result will be found in the "help/includes/templated" directory.'
task :render do
  sh '_scripts/render'
  Rake::Task['includes:maintain_all'].invoke
end
