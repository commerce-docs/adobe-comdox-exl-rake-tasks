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

class UtilityTasksIntegrationTest < Minitest::Test
  include IntegrationTestHelper

  def setup
    setup_test_workspace
  end

  def teardown
    teardown_test_workspace
  end

  def test_render_builds_jekyll_site_and_copies_templated_output
    create_test_file('_jekyll/templated/example.md', <<~MARKDOWN)
      ---
      title: Example
      ---
      Hello {{ "world" }}
    MARKDOWN

    output = run_task_in_workspace('render')

    assert_includes output, 'Rendering templated files...'
    assert_includes output, 'Templates rendered successfully.'

    # Jekyll builds the template to .html, then the task renames it back to
    # .md (see RenderTaskHelper.rename_html_to_md) so it can be used as an
    # ExL include snippet, keeping the rendered HTML content.
    assert file_exists?('help/_includes/templated/example.md'),
           'Rendered template should be copied to help/_includes/templated/'
    assert_includes read_test_file('help/_includes/templated/example.md'), 'Hello world'
  end

  def test_render_also_runs_include_maintenance
    create_test_file('_jekyll/templated/example.md', <<~MARKDOWN)
      ---
      title: Example
      ---
      Static content.
    MARKDOWN

    output = run_task_in_workspace('render')

    assert_includes output, 'includes:maintain_relationships'
    assert_includes output, 'includes:maintain_timestamps'

    relationships_file = File.join(TEMP_DIR, 'rakelib', 'include-relationships.yml')
    assert File.exist?(relationships_file), 'include-relationships.yml should be created by render'
  end
end
