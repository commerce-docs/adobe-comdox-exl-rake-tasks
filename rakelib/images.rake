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
require 'mini_magick'

# Maximum allowed size for SVG images pushed to ExL repositories
SVG_SIZE_LIMIT_BYTES = 140 * 1024

# Helper methods for image tasks
module ImageTasksHelper
  def self.uncommitted_image_files
    modified = `git ls-files --modified --others --exclude-standard -- ..`.split("\n")
    deleted = `git ls-files --deleted -- ..`.split("\n")
    (modified - deleted).select { |f| File.extname(f) =~ /\.(png|jpg|jpeg|gif)/i }
  end

  def self.image_linked?(content, basename)
    escaped = Regexp.escape(basename)
    content.match?(/!\[[^\]]*\]\([^)]*#{escaped}[^)]*\)/) ||
      content.match?(/<img\s+[^>]*src=["'][^"']*#{escaped}["']/)
  end

  def self.report_unused_images(images)
    if images.empty?
      puts 'No unlinked images'.green
    else
      images.each { |img| puts "No links for #{img}".yellow }
      puts "Found #{images.size} dangling images".red
    end
  end

  def self.imagemagick_available?
    # ImageMagick 7+ provides `magick`; older 6.x installs only have `convert`.
    system('command -v magick > /dev/null 2>&1') || system('command -v convert > /dev/null 2>&1')
  end

  def self.svgs_for_path(path)
    return [path] if File.file?(path)

    Dir["#{path}/**/*.svg"]
  end

  def self.oversized_svgs(svgs, limit_bytes = SVG_SIZE_LIMIT_BYTES)
    svgs.select { |svg| File.size(svg) > limit_bytes }
  end

  def self.report_oversized_svgs(oversized, limit_bytes = SVG_SIZE_LIMIT_BYTES)
    limit_kb = limit_bytes / 1024

    if oversized.empty?
      puts "All SVG images are within the #{limit_kb} KB size limit".green
    else
      oversized.each { |svg| puts "#{svg} exceeds #{limit_kb} KB (#{File.size(svg)} bytes)".red }
      puts "Found #{oversized.size} oversized SVG images".red
    end
  end

  def self.convert_svg_to_png(svg)
    png = svg.sub(/\.svg\z/i, '.png')
    image = MiniMagick::Image.open(svg)
    image.format('png')
    image.write(png)
    puts "Converted #{svg} -> #{png}".green
  rescue MiniMagick::Error => e
    puts "Failed to convert #{svg}: #{e.message}".red
  end
end

namespace :images do
  desc 'Optimize images in modified uncommitted files. For other images, use "path".'
  task :optimize do
    puts "\nChecking images ...".magenta
    path = ENV.fetch('path', nil)

    unless path
      puts 'Looking in uncommitted files ...'.blue
      files = ImageTasksHelper.uncommitted_image_files
      next puts 'No images to check.'.magenta if files.empty?

      path = files.join(' ')
    end

    ENV['path'] = path
    if Dir["#{path}/**/*.svg"].any?
      check_size_task = Rake::Task['images:check_size']
      check_size_task.reenable
      check_size_task.invoke
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
      next if File.symlink?(file)

      content = File.read(file)
      images.delete_if { |img| ImageTasksHelper.image_linked?(content, File.basename(img)) }
    end

    ImageTasksHelper.report_unused_images(images)
  end

  desc 'Convert SVG images to PNG format by path, e.g. rake images:svg_to_png path=../help/assets/image.svg ' \
       '(keeps the original SVG).'
  task :svg_to_png do
    path = ENV.fetch('path', nil)
    unless path
      puts 'Please provide a path to the SVG images.'.red
      puts 'Example: rake images:svg_to_png path=../help/assets/image.svg'.yellow
      next
    end

    svgs = ImageTasksHelper.svgs_for_path(path)
    next puts 'No SVG images found.'.magenta if svgs.empty?

    unless ImageTasksHelper.imagemagick_available?
      puts 'ImageMagick is required to convert SVGs to PNG.'.red
      puts 'Install it with "brew install imagemagick" (macOS) or "apt-get install imagemagick" (Debian/Ubuntu).'.yellow
      next
    end

    svgs.each { |svg| ImageTasksHelper.convert_svg_to_png(svg) }
  end

  desc 'Check SVG images against the size limit by path, e.g. rake images:check_size path=../help/assets.'
  task :check_size do
    path = ENV.fetch('path', nil)
    unless path
      puts 'Please provide a path to the SVG images.'.red
      puts 'Example: rake images:check_size path=../help/assets'.yellow
      next
    end

    svgs = ImageTasksHelper.svgs_for_path(path)
    next puts 'No SVG images found.'.magenta if svgs.empty?

    oversized = ImageTasksHelper.oversized_svgs(svgs)
    ImageTasksHelper.report_oversized_svgs(oversized)
  end
end
