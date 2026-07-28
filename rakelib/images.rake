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
    content.match?(/!\[.*?\]\([^)]*#{escaped}[^)]*\)/) ||
      content.match?(/<img\s+[^>]*src=["'][^"']*#{escaped}["']/)
  end

  # images:svg_to_png keeps the source SVG alongside its rendered PNG, and either one may be
  # the one actually referenced in Markdown. So an SVG whose own filename isn't linked should
  # still be treated as used if a same-named PNG sibling is linked instead.
  def self.svg_png_counterpart_used?(image, contents)
    return false unless File.extname(image).casecmp('.svg').zero?

    png_counterpart = image.sub(/\.svg\z/i, '.png')
    return false unless File.exist?(png_counterpart)

    basename = File.basename(png_counterpart)
    contents.any? { |content| image_linked?(content, basename) }
  end

  def self.filter_used_images(images)
    contents = Dir['../help/**/*.md'].reject { |f| File.symlink?(f) }.map { |f| File.read(f) }

    images.delete_if { |img| contents.any? { |content| image_linked?(content, File.basename(img)) } }
    images.delete_if { |img| svg_png_counterpart_used?(img, contents) }
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

  def self.rsvg_convert_available?
    system('command -v rsvg-convert > /dev/null 2>&1')
  end

  CHROME_PATH_CANDIDATES = %w[google-chrome google-chrome-stable chromium chromium-browser microsoft-edge].freeze

  CHROME_APP_CANDIDATES = [
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/Applications/Chromium.app/Contents/MacOS/Chromium',
    '/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge'
  ].freeze

  def self.chrome_binary
    return ENV['CHROME_PATH'] if ENV['CHROME_PATH'] && File.executable?(ENV['CHROME_PATH'])

    found = CHROME_PATH_CANDIDATES.find { |bin| system("command -v #{bin} > /dev/null 2>&1") }
    return found if found

    CHROME_APP_CANDIDATES.find { |path| File.executable?(path) }
  end

  def self.chrome_available?
    !chrome_binary.nil?
  end

  def self.svg_conversion_available?
    rsvg_convert_available? || imagemagick_available? || chrome_available?
  end

  # draw.io/diagrams.net exports embed rich text as HTML via <foreignObject>, with a plain
  # <text> fallback for renderers without HTML support. Neither rsvg-convert nor ImageMagick
  # render foreignObject, so they silently fall back to the truncated placeholder text.
  def self.foreign_object_svg?(svg)
    File.read(svg).include?('<foreignObject')
  end

  def self.svg_dimensions(svg)
    default = [1600, 1200]
    root = File.read(svg)[/<svg[^>]*>/m]
    return default unless root

    width = root[/\bwidth="([\d.]+)(?:px)?"/, 1]
    height = root[/\bheight="([\d.]+)(?:px)?"/, 1]
    return [width.to_f.ceil, height.to_f.ceil] if width && height

    view_box = root.match(/viewBox="[-\d.]+\s+[-\d.]+\s+([\d.]+)\s+([\d.]+)"/)
    return [view_box[1].to_f.ceil, view_box[2].to_f.ceil] if view_box

    default
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

    if foreign_object_svg?(svg)
      return convert_with_chrome(svg, png) if chrome_available?

      warn_missing_chrome(svg)
    end

    # Prefer rsvg-convert: ImageMagick's built-in SVG renderer takes priority over its
    # rsvg-convert delegate on many builds and fails to resolve named fonts in SVG text.
    return convert_with_rsvg(svg, png) if rsvg_convert_available?
    return convert_with_imagemagick(svg, png) if imagemagick_available?
    return convert_with_chrome(svg, png) if chrome_available?

    puts "Failed to convert #{svg}: no SVG conversion tool is available".red
  end

  def self.warn_missing_chrome(svg)
    puts "#{svg} embeds HTML content (foreignObject); install Google Chrome or Chromium " \
         'for accurate text rendering, otherwise it will be replaced with a placeholder.'.yellow
  end

  def self.chrome_screenshot_command(svg, png)
    width, height = svg_dimensions(svg)
    svg_url = "file://#{File.expand_path(svg).gsub(' ', '%20')}"

    [
      chrome_binary, '--headless=new', '--disable-gpu', '--hide-scrollbars',
      "--window-size=#{width},#{height}", '--force-device-scale-factor=1',
      "--screenshot=#{File.expand_path(png)}", svg_url
    ]
  end

  def self.convert_with_chrome(svg, png)
    if system(*chrome_screenshot_command(svg, png))
      puts "Converted #{svg} -> #{png}".green
    else
      puts "Failed to convert #{svg}: headless Chrome exited with an error".red
    end
  end

  def self.convert_with_rsvg(svg, png)
    if system('rsvg-convert', '--dpi-x', '96', '--dpi-y', '96', '-o', png, svg)
      puts "Converted #{svg} -> #{png}".green
    else
      puts "Failed to convert #{svg}: rsvg-convert exited with an error".red
    end
  end

  def self.convert_with_imagemagick(svg, png)
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

    # Pass each path as its own argv entry (no shell involved) so filenames containing shell
    # metacharacters (quotes, globs, `$`, `;`, etc.) are never re-interpreted by a shell.
    # Paths are split on whitespace, so file names must not contain spaces.
    success = system('bundle', 'exec', 'image_optim', '--recursive', '--no-svgo', *path.split)
    unless success
      raise "Image optimization failed for: #{path}. " \
            'Verify each file exists and that file names contain no spaces.'
    end
  end

  desc 'Find unused images.'
  task :unused do
    puts 'Running a task for finding unused images (png,svg,jpeg,jpg,ico)'.magenta
    images = FileList['../help/**/*.{png,svg,jpeg,jpg,ico}']
    puts "The project contains a total of #{images.size} images."

    puts 'Checking for unlinked images...'
    ImageTasksHelper.filter_used_images(images)

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

    unless ImageTasksHelper.svg_conversion_available?
      puts 'librsvg, ImageMagick, or Google Chrome/Chromium is required to convert SVGs to PNG.'.red
      puts 'Install with "brew install librsvg imagemagick" (macOS) or ' \
           '"apt-get install librsvg2-bin imagemagick" (Debian/Ubuntu), or install Google Chrome.'.yellow
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
