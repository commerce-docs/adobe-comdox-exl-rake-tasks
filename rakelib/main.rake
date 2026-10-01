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
require 'fileutils'
require 'yaml'
require 'colorator'
require 'date'
require 'tzinfo'

# NOTE: Individual namespace tasks have been moved to separate files:
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
  since = ENV.fetch('since', nil)
  current_file = '_data/whats-new.yml'
  generated_file = 'tmp/whats-new.yml'
  current_data = YAML.load_file current_file
  last_update = current_data['updated']
  print 'Generating data for the What\'s New digest: '.magenta

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
  Configure helper_dir and templated_dest in the repository "_config.yml".
  Defaults to "_jekyll" and "help/_includes/templated" in the repository root.
  Requires Jekyll to be installed in the consuming project.'
task :render do
  RenderTaskHelper.render_templates
end

# Helper module for render task
module RenderTaskHelper
  HELPER_DIR = '_jekyll'
  TEMPLATED_DEST = 'help/_includes/templated'

  def self.render_templates
    puts 'Rendering templated files...'.magenta

    configure_paths
    verify_jekyll_installed
    run_jekyll_build
    rename_html_to_md
    copy_to_includes

    puts 'Templates rendered successfully.'.green
  end

  def self.configure_paths
    repository_dir = File.basename(Dir.pwd) == 'rakelib' ? File.expand_path('..') : Dir.pwd
    config = load_config(repository_dir)
    @helper_dir = configured_path(config, 'helper_dir', HELPER_DIR, repository_dir)
    @templated_dest = configured_path(config, 'templated_dest', TEMPLATED_DEST, repository_dir)
    @site_dir = File.join(@helper_dir, '_site')
    @templated_src = File.join(@site_dir, 'templated')
  end

  def self.load_config(repository_dir)
    config_path = File.join(repository_dir, '_config.yml')
    return {} unless File.file?(config_path)

    config = YAML.safe_load_file(config_path, permitted_classes: [Date, Time], aliases: true) || {}
    raise ArgumentError, '_config.yml must contain a YAML mapping.' unless config.is_a?(Hash)

    config
  end

  def self.configured_path(config, key, default, repository_dir)
    path = config.fetch(key, default)
    unless path.is_a?(String) && !path.strip.empty?
      raise ArgumentError, "#{key} in _config.yml must be a non-empty string."
    end

    File.expand_path(path, repository_dir)
  end

  def self.verify_jekyll_installed
    return if system('bundle exec jekyll --version > /dev/null 2>&1')

    abort 'Error: Jekyll is required for the render task. Add "gem \'jekyll\'" to your Gemfile.'.red
  end

  def self.run_jekyll_build
    puts 'Running Jekyll build...'.blue
    Dir.chdir(@helper_dir) do
      success = system('bundle exec jekyll build --disable-disk-cache')
      abort 'Jekyll build failed.'.red unless success
    end
  end

  def self.rename_html_to_md
    puts 'Converting .html files to .md...'.blue
    Dir.glob("#{@site_dir}/**/*.html").each do |html_file|
      md_file = html_file.sub(/\.html$/, '.md')
      FileUtils.mv(html_file, md_file)
    end
  end

  def self.copy_to_includes
    return unless Dir.exist?(@templated_src)

    puts "Copying rendered templates to #{@templated_dest}/...".blue
    FileUtils.mkdir_p(@templated_dest)
    FileUtils.cp_r(Dir.glob("#{@templated_src}/*"), @templated_dest)
  end
end
