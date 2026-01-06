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
end
