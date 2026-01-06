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

# rubocop:disable Metrics/ClassLength, Metrics/MethodLength
class IncludesTasksIntegrationTest < Minitest::Test
  include IntegrationTestHelper

  def setup
    setup_test_workspace
  end

  def teardown
    teardown_test_workspace
  end

  def test_maintain_relationships_creates_yaml_file
    # Create a main file that includes a snippet
    create_test_file('help/test-doc.md', <<~MARKDOWN)
      ---
      title: Test Document
      ---

      # Test Document

      This is a test document with an include:

      {{$include /help/_includes/snippet.md}}

      More content here.
    MARKDOWN

    # Create the include file
    create_test_file('help/_includes/snippet.md', <<~MARKDOWN)
      This is a reusable snippet.
    MARKDOWN

    output = run_task_in_workspace('includes:maintain_relationships')

    # Verify the task ran successfully
    assert_includes output, 'includes:maintain_relationships'
    assert_includes output, 'Successfully discovered'

    # Verify the relationships file was created (in rakelib dir where task runs)
    relationships_file = File.join(TEMP_DIR, 'rakelib', 'include-relationships.yml')
    assert File.exist?(relationships_file), 'include-relationships.yml should be created'

    # Verify the file content
    relationships = YAML.load_file(relationships_file)
    assert relationships.key?('metadata'), 'Should have metadata section'
    assert relationships.key?('relationships'), 'Should have relationships section'
  end

  def test_maintain_relationships_discovers_include_references
    # Create main file with include reference
    create_test_file('help/docs/guide.md', <<~MARKDOWN)
      ---
      title: Guide
      ---

      {{$include /help/_includes/common-note.md}}
    MARKDOWN

    # Create the include file
    create_test_file('help/_includes/common-note.md', <<~MARKDOWN)
      > **Note:** This is important.
    MARKDOWN

    run_task_in_workspace('includes:maintain_relationships')

    relationships_file = File.join(TEMP_DIR, 'rakelib', 'include-relationships.yml')
    relationships = YAML.load_file(relationships_file)

    # Check that the relationship was discovered
    assert relationships['relationships'].key?('docs/guide.md'),
           'Should discover relationship for docs/guide.md'
    assert_includes relationships['relationships']['docs/guide.md'],
                    '/help/_includes/common-note.md'
  end

  def test_unused_includes_finds_orphaned_files
    # Create an include file that is NOT referenced anywhere
    create_test_file('help/_includes/orphan.md', <<~MARKDOWN)
      This include is not used anywhere.
    MARKDOWN

    # Create a main file that does NOT include anything
    create_test_file('help/main.md', <<~MARKDOWN)
      ---
      title: Main
      ---

      Just regular content, no includes.
    MARKDOWN

    output = run_task_in_workspace('includes:unused')

    # Should report the orphaned include
    assert_includes output, 'includes:unused'
    assert_includes output, 'orphan.md'
  end

  def test_unused_includes_no_orphans
    # Create an include file
    create_test_file('help/_includes/used-snippet.md', <<~MARKDOWN)
      This is used.
    MARKDOWN

    # Create a main file that references it with proper ExL include syntax
    create_test_file('help/main.md', <<~MARKDOWN)
      ---
      title: Main
      ---

      Here is some included content:

      {{$include /help/_includes/used-snippet.md}}
    MARKDOWN

    output = run_task_in_workspace('includes:unused')

    assert_includes output, 'includes:unused'
    # Should not find unused includes (properly referenced with ExL syntax)
    refute_includes output, 'used-snippet.md'
  end

  def test_include_mentioned_without_exl_syntax_is_reported_unused
    # Includes must be properly linked with ExL syntax to be considered used.
    # Simply mentioning the filename in text is not enough.
    create_test_file('help/_includes/mentioned-only.md', <<~MARKDOWN)
      This snippet content.
    MARKDOWN

    # Just mention the filename in text without ExL include syntax
    create_test_file('help/doc.md', <<~MARKDOWN)
      # Notes

      Remember to update mentioned-only.md when the content changes.
    MARKDOWN

    output = run_task_in_workspace('includes:unused')

    # Include SHOULD be reported as unused (no proper ExL syntax)
    assert_includes output, 'mentioned-only.md'
  end

  def test_maintain_relationships_handles_empty_directory
    # Create empty includes directory (already created in setup)
    # Create a main file with no includes
    create_test_file('help/simple.md', <<~MARKDOWN)
      ---
      title: Simple
      ---

      No includes here.
    MARKDOWN

    output = run_task_in_workspace('includes:maintain_relationships')

    # Should complete without error
    assert_includes output, 'Successfully discovered'

    # Should create file with 0 relationships
    relationships_file = File.join(TEMP_DIR, 'rakelib', 'include-relationships.yml')
    relationships = YAML.load_file(relationships_file)
    assert_equal 0, relationships['metadata']['total_relationships']
  end

  def test_maintain_relationships_metadata_has_required_fields
    create_test_file('help/doc.md', 'Content')

    run_task_in_workspace('includes:maintain_relationships')

    relationships_file = File.join(TEMP_DIR, 'rakelib', 'include-relationships.yml')
    relationships = YAML.load_file(relationships_file)
    metadata = relationships['metadata']

    assert metadata.key?('last_updated'), 'Should have last_updated'
    assert metadata.key?('description'), 'Should have description'
    assert metadata.key?('total_relationships'), 'Should have total_relationships'
    assert metadata.key?('auto_discovered'), 'Should have auto_discovered'
    assert metadata.key?('discovery_date'), 'Should have discovery_date'
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/MethodLength
