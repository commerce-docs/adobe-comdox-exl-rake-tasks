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

  def test_maintain_timestamps_processes_existing_relationships
    create_test_file('help/test-doc.md', <<~MARKDOWN)
      ---
      title: Test Document
      ---

      {{$include /help/_includes/snippet.md}}
    MARKDOWN
    create_test_file('help/_includes/snippet.md', 'This is a reusable snippet.')

    # include-relationships.yml must already exist, or the task exits the process
    run_task_in_workspace('includes:maintain_relationships')
    output = run_task_in_workspace('includes:maintain_timestamps')

    assert_includes output, 'includes:maintain_timestamps'
    assert_includes output, 'Successfully updated timestamps'
    assert_includes output, 'Task completed: includes:maintain_timestamps'
  end

  def test_unused_includes_excludes_directories
    # A nested directory under help/_includes whose files are never referenced.
    create_test_file('help/_includes/release-notes/highlights/security.md', <<~MARKDOWN)
      This include is not used anywhere.
    MARKDOWN

    create_test_file('help/main.md', <<~MARKDOWN)
      ---
      title: Main
      ---

      Just regular content, no includes.
    MARKDOWN

    output = run_task_in_workspace('includes:unused')

    # Only the file itself is a candidate -- the 2 containing directories
    # (release-notes, release-notes/highlights) must be filtered out up front.
    assert_includes output, 'Status: Found 1 include files to check'
    # The unused file itself should be reported...
    assert_includes output, 'security.md'
    # ...and it should be the only entry reported as unused.
    assert_includes output, 'Status: 1 unlinked includes detected'
  end

  def test_unused_includes_handles_duplicate_basenames_in_different_directories
    # Two include files with the same basename in different directories.
    create_test_file('help/_includes/a/notes.md', 'Notes A')
    create_test_file('help/_includes/b/notes.md', 'Notes B')

    # Only the one in `a/` is referenced.
    create_test_file('help/main.md', <<~MARKDOWN)
      ---
      title: Main
      ---

      {{$include /help/_includes/a/notes.md}}
    MARKDOWN

    output = run_task_in_workspace('includes:unused')

    # Only the unreferenced b/notes.md should be reported as unused.
    assert_includes output, 'b/notes.md'
    refute_includes output, 'a/notes.md'
  end

  def test_unused_includes_handles_nested_path_matching_a_shorter_paths_suffix
    # notes.md exists both on its own and nested one level deeper under sub/,
    # so the shorter path's relative form ("a/notes.md") is a literal suffix
    # of the deeper one's ("sub/a/notes.md").
    create_test_file('help/_includes/a/notes.md', 'Notes A')
    create_test_file('help/_includes/sub/a/notes.md', 'Notes Sub A')

    # Only the deeper one is referenced.
    create_test_file('help/main.md', <<~MARKDOWN)
      ---
      title: Main
      ---

      {{$include /help/_includes/sub/a/notes.md}}
    MARKDOWN

    output = run_task_in_workspace('includes:unused')

    # The shorter a/notes.md must still be reported as unused -- its relative
    # path being a suffix of the referenced path must not count as a match.
    assert_includes output, 'a/notes.md'
    refute_includes output, 'sub/a/notes.md'
  end

  def test_maintain_all_runs_both_tasks_in_sequence
    create_test_file('help/doc.md', <<~MARKDOWN)
      ---
      title: Doc
      ---

      {{$include /help/_includes/note.md}}
    MARKDOWN
    create_test_file('help/_includes/note.md', 'A note.')

    output = run_task_in_workspace('includes:maintain_all')

    assert_includes output, 'includes:maintain_relationships'
    assert_includes output, 'includes:maintain_timestamps'
    assert_includes output, 'All include management tasks completed successfully'
    assert_includes output, 'Task completed: includes:maintain_all'

    relationships_file = File.join(TEMP_DIR, 'rakelib', 'include-relationships.yml')
    assert File.exist?(relationships_file), 'include-relationships.yml should be created'
  end

  def test_maintain_metadata_timestamps_writes_last_update_from_git_history
    write_topic_with_include
    init_git_repo
    git_commit_all('Add topic and include', '2026-01-15T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')

    assert_includes read_test_file('help/topic.md'), 'last-update: 2026-01-15'
  end

  def test_metadata_timestamp_ignores_front_matter_only_commit
    write_topic_with_include
    init_git_repo
    git_commit_all('Initial content', '2026-01-10T12:00:00')

    # A later commit that only edits front matter must NOT advance last-update.
    create_test_file('help/topic.md', topic_body(front_matter: "title: Topic\nexl-id: abc-123"))
    git_commit_all('Add exl-id to front matter', '2026-02-20T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')

    body = read_test_file('help/topic.md')
    assert_includes body, 'last-update: 2026-01-10'
    refute_includes body, 'last-update: 2026-02-20'
  end

  def test_metadata_timestamp_ignores_html_comment_only_commit
    write_topic_with_include
    init_git_repo
    git_commit_all('Initial content', '2026-01-10T12:00:00')

    # The sibling includes:maintain_timestamps task appends an HTML comment marker;
    # such an invisible edit must not advance last-update.
    create_test_file('help/topic.md', "#{topic_body}\n<!-- Last updated from includes: 2026-03-01 09:00:00 -->\n")
    git_commit_all('Append include timestamp comment', '2026-03-01T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')

    body = read_test_file('help/topic.md')
    assert_includes body, 'last-update: 2026-01-10'
    refute_includes body, 'last-update: 2026-03-01'
  end

  def test_metadata_timestamp_uses_latest_of_topic_and_include
    write_topic_with_include
    init_git_repo
    git_commit_all('Initial content', '2026-01-10T12:00:00')

    # Only the include changes, and more recently than the topic itself.
    create_test_file('help/_includes/note.md', 'A revised note.')
    git_commit_all('Revise include', '2026-04-05T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')

    assert_includes read_test_file('help/topic.md'), 'last-update: 2026-04-05'
  end

  def test_maintain_metadata_timestamps_is_idempotent
    write_topic_with_include
    init_git_repo
    git_commit_all('Add topic and include', '2026-01-15T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')
    after_first = read_test_file('help/topic.md')
    run_task_in_workspace('includes:maintain_metadata_timestamps')
    after_second = read_test_file('help/topic.md')

    assert_equal after_first, after_second
    assert_equal 1, after_second.scan('last-update:').size
  end

  def test_metadata_timestamp_does_not_shell_out_for_paths_with_metacharacters
    # The include filename contains a shell command substitution. Every git call must
    # pass paths as literal argv entries; if any interpolated it into a shell instead,
    # this would create injected_marker.txt.
    include_name = 'note$(touch injected_marker.txt).md'
    create_test_file('help/topic.md', <<~MARKDOWN)
      ---
      title: Topic
      ---

      # Topic

      Some visible prose.

      {{$include /help/_includes/#{include_name}}}
    MARKDOWN
    create_test_file("help/_includes/#{include_name}", 'A note.')
    init_git_repo
    git_commit_all('Add topic and include', '2026-01-15T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')

    assert_empty Dir.glob(File.join(TEMP_DIR, '**', 'injected_marker.txt')),
                 'shell metacharacters in an include path were executed'
  end

  def test_maintain_metadata_timestamps_fails_for_topic_without_front_matter
    # A topic with includes but no front matter has nowhere to write last-update, so the
    # task must fail loudly rather than silently skip it.
    create_test_file('help/topic.md', <<~MARKDOWN)
      # Topic

      Some visible prose.

      {{$include /help/_includes/note.md}}
    MARKDOWN
    create_test_file('help/_includes/note.md', 'A note.')
    init_git_repo
    git_commit_all('Add topic and include', '2026-01-15T12:00:00')

    output = run_task_in_workspace('includes:maintain_metadata_timestamps')

    assert_includes output, 'No front matter'
  end

  def test_maintain_metadata_timestamps_is_atomic_when_a_topic_lacks_front_matter
    # aaa.md (sorted first, so processed first) has front matter; zzz.md does not. The run
    # must fail without writing last-update to aaa.md -- it is all-or-nothing.
    create_test_file('help/aaa.md', <<~MARKDOWN)
      ---
      title: Good
      ---

      # Good

      {{$include /help/_includes/note.md}}
    MARKDOWN
    create_test_file('help/zzz.md', <<~MARKDOWN)
      # Bad

      {{$include /help/_includes/note.md}}
    MARKDOWN
    create_test_file('help/_includes/note.md', 'A note.')
    init_git_repo
    git_commit_all('Add topics and include', '2026-01-15T12:00:00')

    output = run_task_in_workspace('includes:maintain_metadata_timestamps')

    assert_includes output, 'No front matter'
    refute_includes read_test_file('help/aaa.md'), 'last-update:'
  end

  def test_metadata_timestamp_ignores_move_to_include_that_does_not_change_rendered_output
    # Inline prose is relocated verbatim into an include on a feature branch and merged to
    # main. Readers see an identical rendered page, so the publish must not advance
    # last-update past the date the prose was actually authored.
    create_test_file('help/topic.md', topic_with_body('The quick brown fox jumps over the lazy dog.'))
    init_git_repo
    git_commit_all('Author inline prose', '2026-01-10T12:00:00')

    git_checkout('feat', create: true)
    create_test_file('help/_includes/fox.md', "The quick brown fox jumps over the lazy dog.\n")
    create_test_file('help/topic.md', topic_with_body('{{$include /help/_includes/fox.md}}'))
    git_commit_all('Move prose into an include', '2026-02-20T12:00:00')

    git_checkout('main')
    git_merge('feat', 'Merge PR: move prose to include', '2026-02-25T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')

    body = read_test_file('help/topic.md')
    assert_includes body, 'last-update: 2026-01-10'
    refute_includes body, 'last-update: 2026-02-25'
  end

  def test_metadata_timestamp_advances_to_publish_when_move_to_include_changes_rendered_output
    # Same move-to-include, but the include adds a heading the page never had, so the
    # rendered output genuinely changes. The date must advance to the production publish
    # (the merge to main) -- not the original prose date, and not the feature-branch commit.
    create_test_file('help/topic.md', topic_with_body('The quick brown fox jumps over the lazy dog.'))
    init_git_repo
    git_commit_all('Author inline prose', '2026-01-10T12:00:00')

    git_checkout('feat', create: true)
    create_test_file('help/_includes/fox.md', "## Reference\n\nThe quick brown fox jumps over the lazy dog.\n")
    create_test_file('help/topic.md', topic_with_body('{{$include /help/_includes/fox.md}}'))
    git_commit_all('Move prose into an include and add a heading', '2026-02-20T12:00:00')

    git_checkout('main')
    git_merge('feat', 'Merge PR: move prose to include', '2026-02-25T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')

    assert_includes read_test_file('help/topic.md'), 'last-update: 2026-02-25'
  end

  def test_metadata_timestamp_follows_nested_includes
    # topic -> outer include -> inner include. Editing the innermost include changes the
    # topic's rendered output and must advance last-update, even though the topic never
    # references the inner include directly (so the relationships index does not list it).
    create_test_file('help/topic.md', topic_with_body('{{$include /help/_includes/outer.md}}'))
    create_test_file('help/_includes/outer.md', "Outer intro.\n\n{{$include /help/_includes/inner.md}}\n")
    create_test_file('help/_includes/inner.md', "Original inner text.\n")
    init_git_repo
    git_commit_all('Add topic with nested includes', '2026-01-10T12:00:00')

    create_test_file('help/_includes/inner.md', "Revised inner text.\n")
    git_commit_all('Edit the innermost include', '2026-05-01T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')

    assert_includes read_test_file('help/topic.md'), 'last-update: 2026-05-01'
  end

  def test_metadata_timestamp_reflects_production_branch_not_the_checked_out_branch
    # last-update tracks what readers see on main. An unmerged edit on the branch the task
    # happens to run from must not leak into the date, even though that edit is what gets
    # written to disk.
    create_test_file('help/topic.md', topic_with_body('{{$include /help/_includes/note.md}}'))
    create_test_file('help/_includes/note.md', "A note.\n")
    init_git_repo
    git_commit_all('Publish topic', '2026-01-10T12:00:00')

    git_checkout('feat', create: true)
    create_test_file('help/_includes/note.md', "A substantially rewritten note.\n")
    git_commit_all('Unpublished rewrite on a feature branch', '2026-06-01T12:00:00')

    run_task_in_workspace('includes:maintain_metadata_timestamps')

    body = read_test_file('help/topic.md')
    assert_includes body, 'last-update: 2026-01-10'
    refute_includes body, 'last-update: 2026-06-01'
  end

  private

  # A topic with front matter wrapping a single body line (prose or an include directive).
  def topic_with_body(body)
    <<~MARKDOWN
      ---
      title: Topic
      ---

      # Topic

      #{body}
    MARKDOWN
  end

  # A topic that references one include, plus the include itself.
  def write_topic_with_include
    create_test_file('help/topic.md', topic_body)
    create_test_file('help/_includes/note.md', 'A note.')
  end

  def topic_body(front_matter: 'title: Topic')
    <<~MARKDOWN
      ---
      #{front_matter}
      ---

      # Topic

      Some visible prose.

      {{$include /help/_includes/note.md}}
    MARKDOWN
  end

  def init_git_repo
    run_git('init', '-q', TEMP_DIR)
    # Pin the default branch so merge-based tests can check out 'main' deterministically,
    # regardless of the host git's init.defaultBranch setting.
    run_git('-C', TEMP_DIR, 'symbolic-ref', 'HEAD', 'refs/heads/main')
    run_git('-C', TEMP_DIR, 'config', 'user.email', 'test@example.com')
    run_git('-C', TEMP_DIR, 'config', 'user.name', 'Test')
    run_git('-C', TEMP_DIR, 'config', 'commit.gpgsign', 'false')
    run_git('-C', TEMP_DIR, 'config', 'core.hooksPath', File::NULL)
    assert_workspace_git_isolated
  end

  # Fails loudly if the workspace is not its own git repository. In a restricted sandbox
  # `git init` cannot create the nested repo, so git commands against TEMP_DIR resolve
  # upward to the gem's own repository -- and the tests' add/commit/merge would then
  # rewrite real project history. Abort here, before any commit, rather than corrupt it.
  def assert_workspace_git_isolated
    toplevel = IO.popen(['git', '-C', TEMP_DIR, 'rev-parse', '--show-toplevel'], err: File::NULL, &:read).strip
    return if !toplevel.empty? && File.identical?(toplevel, TEMP_DIR)

    raise "Workspace git repo is not isolated: `git -C #{TEMP_DIR}` resolved to " \
          "#{toplevel.empty? ? '(no repository)' : toplevel}, not the workspace itself. " \
          'This happens in a restricted sandbox where `git init` cannot create the nested ' \
          'repo; run the integration tests unsandboxed (see README).'
  end

  def git_commit_all(message, iso_date)
    run_git('-C', TEMP_DIR, 'add', '-A')
    env = { 'GIT_AUTHOR_DATE' => iso_date, 'GIT_COMMITTER_DATE' => iso_date }
    system(env, 'git', '-C', TEMP_DIR, 'commit', '-q', '-m', message, out: File::NULL, err: File::NULL)
  end

  def git_checkout(branch, create: false)
    args = ['-C', TEMP_DIR, 'checkout', '-q']
    args << '-b' if create
    run_git(*args, branch)
  end

  # Merges branch into the current branch with a real merge commit (no fast-forward),
  # mirroring how a PR lands on the mainline.
  def git_merge(branch, message, iso_date)
    env = { 'GIT_AUTHOR_DATE' => iso_date, 'GIT_COMMITTER_DATE' => iso_date }
    system(env, 'git', '-C', TEMP_DIR, 'merge', '-q', '--no-ff', '-m', message, branch,
           out: File::NULL, err: File::NULL)
  end

  def run_git(*)
    system('git', *, out: File::NULL, err: File::NULL)
  end
end
# rubocop:enable Metrics/ClassLength, Metrics/MethodLength
