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

# Image Management Tasks
# This file contains rake tasks for managing and optimizing images

require 'colorator'

namespace :images do
  desc 'Optimize images in modified uncommitted files. For other images, use "path" such as "bundle exec rake images:optimize path=../path/to/dir/or/file".'
  task :optimize do
    puts
    puts 'Checking images ...'.magenta
    path = ENV['path']

    unless path
      puts 'Looking in uncommitted files ...'.blue
      modified_files = `git ls-files --modified --others --exclude-standard -- ..`.split("\n")
      deleted_files = `git ls-files --deleted -- ..`.split("\n")
      image_files_to_check = (modified_files - deleted_files).select do |file|
        File.extname(file) =~ /\.(png|jpg|jpeg|gif)/i
      end

      next puts 'No images to check.'.magenta if image_files_to_check.empty?

      path = image_files_to_check.join(' ')
    end

    system "bundle exec image_optim --recursive --no-svgo #{path}"
  end

  desc 'Find unused images.'
  task :unused do
    puts 'Running a task for finding unused images (png,svg,jpeg,jpg,ico)'.magenta
    images = FileList['../help/**/*.{png,svg,jpeg,jpg,ico}']

    puts "The project contains a total of #{images.size} images."

    puts 'Checking for unlinked images...'
    Dir['../help/**/*.{md}'].each do |file|
      # Exclude symlinks
      next if File.symlink? file

      images.delete_if { |image| File.read(file).include?(File.basename(image)) }
    end

    if images.empty?
      puts 'No unlinked images'.green
    else
      images.each do |image|
        puts "No links for #{image}".yellow
      end
      puts "Found #{images.size} dangling images".red
    end
  end
end
