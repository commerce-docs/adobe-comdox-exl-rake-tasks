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

require_relative 'integration_test_helper'

class ImagesTasksIntegrationTest < Minitest::Test
  include IntegrationTestHelper

  def setup
    setup_test_workspace
  end

  def teardown
    teardown_test_workspace
  end

  def test_unused_images_finds_orphaned_images
    # Create an image file that is NOT referenced anywhere
    create_test_file('help/assets/orphan.png', 'fake png content')

    # Create a markdown file that does NOT reference the image
    create_test_file('help/doc.md', <<~MARKDOWN)
      ---
      title: Document
      ---

      Just text content, no images.
    MARKDOWN

    output = run_task_in_workspace('images:unused')

    # Should report the orphaned image
    assert_includes output, 'orphan.png'
    assert_includes output, 'dangling images'
  end

  def test_unused_images_excludes_referenced_images
    # Create an image file
    create_test_file('help/assets/used.png', 'fake png content')

    # Create a markdown file that references the image
    create_test_file('help/doc.md', <<~MARKDOWN)
      ---
      title: Document
      ---

      Here is an image: ![Alt text](used.png)
    MARKDOWN

    output = run_task_in_workspace('images:unused')

    # Should NOT report the used image
    refute_includes output, 'No links for'
  end

  def test_unused_images_no_orphans_message
    # Create an image and reference it with proper Markdown syntax
    create_test_file('help/assets/diagram.png', 'fake png content')
    create_test_file('help/doc.md', <<~MARKDOWN)
      # Documentation

      Here is a diagram:

      ![Architecture diagram](assets/diagram.png)
    MARKDOWN

    output = run_task_in_workspace('images:unused')

    # Should report no unlinked images
    assert_includes output, 'No unlinked images'
  end

  def test_unused_images_counts_total_images
    # Create multiple images
    create_test_file('help/assets/img1.png', 'fake content')
    create_test_file('help/assets/img2.jpg', 'fake content')
    create_test_file('help/assets/img3.svg', 'fake content')

    # Reference all of them with proper Markdown syntax
    create_test_file('help/doc.md', <<~MARKDOWN)
      # Images

      ![Image 1](assets/img1.png)
      ![Image 2](assets/img2.jpg)
      ![Image 3](assets/img3.svg)
    MARKDOWN

    output = run_task_in_workspace('images:unused')

    # Should report total count
    assert_includes output, 'total of 3 images'
  end

  def test_unused_images_handles_no_images
    # Create markdown with no images in directory
    create_test_file('help/doc.md', 'Just text')

    output = run_task_in_workspace('images:unused')

    # Should complete without error
    assert_includes output, 'total of 0 images'
  end

  def test_unused_images_excludes_svg_with_used_png_counterpart
    # images:svg_to_png keeps the source SVG alongside its rendered PNG; only the
    # PNG is referenced in Markdown, so the SVG's own filename is never linked.
    create_test_file('help/assets/diagram.svg', 'fake svg content')
    create_test_file('help/assets/diagram.png', 'fake png content')
    create_test_file('help/doc.md', <<~MARKDOWN)
      ---
      title: Document
      ---

      ![Diagram](assets/diagram.png)
    MARKDOWN

    output = run_task_in_workspace('images:unused')

    # Neither the PNG (directly linked) nor the SVG (used PNG sibling) should be reported
    refute_includes output, 'No links for'
    assert_includes output, 'No unlinked images'
  end

  def test_unused_images_reports_svg_with_unused_png_counterpart
    # The PNG sibling exists but isn't referenced anywhere, so both should still be
    # reported as unused.
    create_test_file('help/assets/orphan.svg', 'fake svg content')
    create_test_file('help/assets/orphan.png', 'fake png content')
    create_test_file('help/doc.md', <<~MARKDOWN)
      ---
      title: Document
      ---

      Just text content, no images.
    MARKDOWN

    output = run_task_in_workspace('images:unused')

    assert_includes output, 'orphan.svg'
    assert_includes output, 'orphan.png'
  end

  def test_optimize_with_no_path_checks_uncommitted
    # This task looks for git-modified files
    # In a fresh test workspace, there are no uncommitted files
    output = run_task_in_workspace('images:optimize')

    # Should report checking images
    assert_includes output, 'Checking images'
  end

  def test_image_with_empty_alt_text_counts_as_used
    # ExL supports ![](image.png) syntax (empty alt text)
    create_test_file('help/assets/diagram.png', 'fake png content')
    create_test_file('help/doc.md', <<~MARKDOWN)
      # Quick reference

      ![](assets/diagram.png)
    MARKDOWN

    output = run_task_in_workspace('images:unused')

    # Image with empty alt text should still be considered used
    refute_includes output, 'diagram.png'
    assert_includes output, 'No unlinked images'
  end

  def test_image_with_html_img_tag_counts_as_used
    # HTML img tags are also valid in ExL markdown
    create_test_file('help/assets/banner.png', 'fake png content')
    create_test_file('help/doc.md', <<~MARKDOWN)
      # Page

      <img src="assets/banner.png" alt="Banner">
    MARKDOWN

    output = run_task_in_workspace('images:unused')

    refute_includes output, 'banner.png'
    assert_includes output, 'No unlinked images'
  end

  def test_image_mentioned_without_link_syntax_is_reported_unused
    # Images must be properly linked with Markdown syntax to be considered used.
    # Simply mentioning the filename in text is not enough.
    create_test_file('help/assets/screenshot.png', 'fake png content')

    # Just mention the filename in text without Markdown image syntax
    create_test_file('help/doc.md', <<~MARKDOWN)
      # Notes

      Remember to update screenshot.png when the UI changes.
    MARKDOWN

    output = run_task_in_workspace('images:unused')

    # Image SHOULD be reported as unused (no proper image link syntax)
    assert_includes output, 'screenshot.png'
    assert_includes output, 'dangling images'
  end

  def test_unused_images_handles_multiple_extensions
    # Create images with different extensions
    create_test_file('help/assets/photo.jpeg', 'fake content')
    create_test_file('help/assets/icon.ico', 'fake content')
    create_test_file('help/assets/vector.svg', 'fake content')

    # Don't reference any of them
    create_test_file('help/doc.md', 'No image references here')

    output = run_task_in_workspace('images:unused')

    # Should find all orphaned images
    assert_includes output, 'photo.jpeg'
    assert_includes output, 'icon.ico'
    assert_includes output, 'vector.svg'
  end

  def test_svg_to_png_without_path_shows_message
    ENV.delete('path')

    output = run_task_in_workspace('images:svg_to_png')

    assert_includes output, 'provide a path'
  end

  def test_svg_to_png_with_no_svgs_found
    create_test_file('help/assets/.keep', '')
    ENV['path'] = File.join(TEMP_DIR, 'help/assets')

    output = run_task_in_workspace('images:svg_to_png')

    assert_includes output, 'No SVG images found'
  ensure
    ENV.delete('path')
  end

  def test_svg_to_png_with_path_to_single_file
    skip 'No SVG conversion tool is installed' unless ImageTasksHelper.svg_conversion_available?

    create_test_file('help/assets/icon.svg', <<~SVG)
      <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
        <rect width="10" height="10" fill="red"/>
      </svg>
    SVG
    ENV['path'] = File.join(TEMP_DIR, 'help/assets/icon.svg')

    output = run_task_in_workspace('images:svg_to_png')

    assert_includes output, 'Converted'
    assert file_exists?('help/assets/icon.png')
  ensure
    ENV.delete('path')
  end

  def test_svg_to_png_reports_missing_imagemagick
    create_test_file('help/assets/icon.svg', '<svg></svg>')
    ENV['path'] = File.join(TEMP_DIR, 'help/assets')

    output = ImageTasksHelper.stub(:svg_conversion_available?, false) do
      run_task_in_workspace('images:svg_to_png')
    end

    assert_includes output, 'is required to convert SVGs to PNG'
    refute file_exists?('help/assets/icon.png')
  ensure
    ENV.delete('path')
  end

  def test_svg_to_png_converts_svg_to_png
    skip 'No SVG conversion tool is installed' unless ImageTasksHelper.svg_conversion_available?

    create_test_file('help/assets/icon.svg', <<~SVG)
      <svg xmlns="http://www.w3.org/2000/svg" width="10" height="10">
        <rect width="10" height="10" fill="red"/>
      </svg>
    SVG
    ENV['path'] = File.join(TEMP_DIR, 'help/assets')

    output = run_task_in_workspace('images:svg_to_png')

    assert_includes output, 'Converted'
    assert file_exists?('help/assets/icon.png')
    assert file_exists?('help/assets/icon.svg'), 'original SVG should be kept, not replaced'
  ensure
    ENV.delete('path')
  end

  def test_svg_to_png_uses_chrome_for_foreign_object_svg
    skip 'Chrome/Chromium is not installed' unless ImageTasksHelper.chrome_available?

    create_test_file('help/assets/diagram.svg', <<~SVG)
      <svg xmlns="http://www.w3.org/2000/svg" width="50" height="50">
        <foreignObject width="100%" height="100%">
          <div xmlns="http://www.w3.org/1999/xhtml">hello</div>
        </foreignObject>
      </svg>
    SVG
    ENV['path'] = File.join(TEMP_DIR, 'help/assets/diagram.svg')

    output = run_task_in_workspace('images:svg_to_png')

    assert_includes output, 'Converted'
    assert file_exists?('help/assets/diagram.png')
  ensure
    ENV.delete('path')
  end

  def test_svg_to_png_warns_when_foreign_object_svg_without_chrome
    create_test_file('help/assets/diagram.svg', <<~SVG)
      <svg xmlns="http://www.w3.org/2000/svg" width="50" height="50">
        <foreignObject width="100%" height="100%">
          <div xmlns="http://www.w3.org/1999/xhtml">hello</div>
        </foreignObject>
      </svg>
    SVG
    ENV['path'] = File.join(TEMP_DIR, 'help/assets/diagram.svg')

    # Stub svg_conversion_available? too so the task-level gate passes regardless of which
    # (if any) SVG conversion tools are actually installed in the environment running this test.
    output = ImageTasksHelper.stub(:chrome_available?, false) do
      ImageTasksHelper.stub(:svg_conversion_available?, true) do
        run_task_in_workspace('images:svg_to_png')
      end
    end

    assert_includes output, 'embeds HTML content'
  ensure
    ENV.delete('path')
  end

  def test_check_size_without_path_shows_message
    ENV.delete('path')

    output = run_task_in_workspace('images:check_size')

    assert_includes output, 'provide a path'
  end

  def test_check_size_with_no_svgs_found
    create_test_file('help/assets/.keep', '')
    ENV['path'] = File.join(TEMP_DIR, 'help/assets')

    output = run_task_in_workspace('images:check_size')

    assert_includes output, 'No SVG images found'
  ensure
    ENV.delete('path')
  end

  def test_check_size_reports_svgs_within_limit
    create_test_file('help/assets/icon.svg', '<svg></svg>')
    ENV['path'] = File.join(TEMP_DIR, 'help/assets')

    output = run_task_in_workspace('images:check_size')

    assert_includes output, 'within the 140 KB size limit'
  ensure
    ENV.delete('path')
  end

  def test_check_size_with_path_to_single_file
    create_test_file('help/assets/icon.svg', '<svg></svg>')
    ENV['path'] = File.join(TEMP_DIR, 'help/assets/icon.svg')

    output = run_task_in_workspace('images:check_size')

    assert_includes output, 'within the 140 KB size limit'
  ensure
    ENV.delete('path')
  end

  def test_check_size_reports_oversized_svgs
    create_test_file('help/assets/large.svg', "<svg>#{'a' * (140 * 1024)}</svg>")
    ENV['path'] = File.join(TEMP_DIR, 'help/assets')

    output = run_task_in_workspace('images:check_size')

    assert_includes output, 'large.svg'
    assert_includes output, 'exceeds 140 KB'
    assert_includes output, 'Found 1 oversized SVG images'
  ensure
    ENV.delete('path')
  end
end
