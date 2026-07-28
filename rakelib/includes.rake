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

# Include Management Tasks
# This file contains rake tasks for managing include relationships and timestamps

require 'yaml'
require 'colorator'
require 'date'
require 'tzinfo'
require 'English'

# rubocop:disable Metrics/ModuleLength

# Helper methods for include management tasks
module IncludesTasksHelper
  RELATIONSHIPS_FILE = 'include-relationships.yml'
  # Git runs from the repo root (one level up from where rake is invoked, e.g.
  # _jekyll/), so paths passed to `git show <ref>:<path>` are repo-relative.
  GIT_ROOT = '..'
  LAST_UPDATE_KEY = /\Alast-update\s*:/
  HTML_COMMENT = /<!--[\s\S]*?-->/
  # ExL include directive: {{$include /help/_includes/...}}. The target path may contain
  # spaces or shell metacharacters, so capture everything up to the closing braces.
  INCLUDE_DIRECTIVE = /\{\{\$include\s+([^}]+?)\}\}/
  # Terminates expansion of a pathological or cyclic include graph.
  MAX_INCLUDE_DEPTH = 10
  # The branch whose history represents what readers see. last-update reflects when a
  # topic's rendered output last changed here, regardless of the branch the task runs on.
  PRODUCTION_REF = 'main'

  def self.current_timestamp
    TZInfo::Timezone.get('America/Chicago').now.strftime('%Y-%m-%d %H:%M:%S %Z')
  end

  def self.discover_relationships
    puts 'Running task: includes:maintain_relationships'.magenta
    puts 'Status: Starting include relationship discovery...'.yellow

    relationships = build_relationships_structure
    populate_relationships(relationships)
    write_relationships(relationships)

    puts "Result: Successfully discovered #{relationships['relationships'].size} include relationships".green
    puts 'Task completed: includes:maintain_relationships'.magenta
  end

  def self.build_relationships_structure
    {
      'metadata' => {
        'last_updated' => current_timestamp,
        'description' => 'Index of main files and their included files for automatic timestamp updates',
        'total_relationships' => 0,
        'auto_discovered' => true,
        'discovery_date' => current_timestamp
      },
      'relationships' => {}
    }
  end

  def self.populate_relationships(relationships)
    include_files = Dir['../help/_includes/**/*'].select { |f| File.file?(f) && f.end_with?('.md') }
    markdown_files = Dir['../help/**/*.md'].reject { |f| f.include?('/_includes/') }

    include_files.each do |include_file|
      include_relative = include_file.sub('../help/_includes/', '')
      find_referencing_files(markdown_files, include_relative, relationships)
    end

    relationships['metadata']['total_relationships'] = relationships['relationships'].size
  end

  def self.find_referencing_files(markdown_files, include_relative, relationships)
    pattern = %r{\{\{\$include\s+/help/_includes/#{Regexp.escape(include_relative)}\}\}}

    markdown_files.each do |main_file|
      next if File.symlink?(main_file)

      content = File.read(main_file)
      next unless content.match?(pattern)

      main_relative = main_file.sub('../help/', '')
      include_path = "/help/_includes/#{include_relative}"
      add_relationship(relationships, main_relative, include_path)
    end
  end

  def self.add_relationship(relationships, main_file, include_path)
    if relationships['relationships'][main_file]
      relationships['relationships'][main_file] << include_path
    else
      relationships['relationships'][main_file] = [include_path]
    end
  end

  def self.write_relationships(relationships)
    puts "Status: Writing relationships to #{RELATIONSHIPS_FILE}...".yellow
    File.write(RELATIONSHIPS_FILE, relationships.to_yaml)
  end

  def self.maintain_timestamps
    puts 'Running task: includes:maintain_timestamps'.magenta
    puts 'Status: Starting timestamp maintenance...'.yellow

    relationships = load_relationships
    return unless relationships

    files_processed = process_timestamp_updates(relationships)

    puts "Result: Successfully updated timestamps in #{files_processed} files".green
    puts 'Task completed: includes:maintain_timestamps'.magenta
  end

  def self.load_relationships
    unless File.exist?(RELATIONSHIPS_FILE)
      puts "Error: #{RELATIONSHIPS_FILE} not found. Run 'bundle exec rake includes:maintain_relationships' first."
      exit 1
    end

    relationships = YAML.load_file(RELATIONSHIPS_FILE)
    puts "Status: Loaded #{relationships['relationships'].size} relationships from #{RELATIONSHIPS_FILE}".yellow
    relationships
  end

  def self.process_timestamp_updates(relationships)
    files_processed = 0

    relationships['relationships'].each do |main_file, includes|
      main_path = "../help/#{main_file}"
      next unless File.exist?(main_path)

      latest = find_latest_include_timestamp(includes)
      next unless latest

      update_file_timestamp(main_path, latest)
      files_processed += 1
    end

    files_processed
  end

  def self.find_latest_include_timestamp(includes)
    latest = nil

    includes.each do |include_path|
      relative = include_path.sub('/help/_includes/', '../help/_includes/')
      timestamp = git_commit_date(relative)
      latest = timestamp if timestamp && (latest.nil? || timestamp > latest)
    end

    latest
  end

  def self.git_commit_date(path)
    output = `git log -1 --format="%aI" -- "#{path}" 2>/dev/null`
    return nil if output.strip.empty?

    DateTime.parse(output.strip).to_time
  rescue StandardError
    nil
  end

  def self.update_file_timestamp(path, timestamp)
    content = File.read(path)
    formatted = timestamp.strftime('%Y-%m-%d %H:%M:%S')
    pattern = /<!--\s*Last updated from includes:\s*(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s*-->\s*$/

    new_content = if content.match?(pattern)
                    content.sub(pattern, "<!-- Last updated from includes: #{formatted} -->\n")
                  else
                    "#{content}\n<!-- Last updated from includes: #{formatted} -->\n"
                  end

    File.write(path, new_content)
  end

  def self.find_unused_includes
    puts 'Running task: includes:unused'.magenta
    puts 'Status: Scanning for unused include files...'.yellow

    includes = FileList['../help/_includes/**/*'].select { |f| File.file?(f) }
    puts "Status: Found #{includes.size} include files to check".yellow

    includes = includes.reject { |f| f == '../help/_includes/snippets.md' }
    filter_used_includes(includes)
    report_unused_includes(includes)

    puts 'Task completed: includes:unused'.magenta
  end

  def self.filter_used_includes(includes)
    Dir['../help/**/*.{md}'].each do |file|
      next if File.symlink?(file)

      content = File.read(file)
      includes.delete_if do |include|
        include_relative = Regexp.escape(include.sub('../help/_includes/', ''))
        content.match?(%r{\{\{\$include\s+/help/_includes/#{include_relative}\}\}})
      end
    end
  end

  def self.report_unused_includes(includes)
    if includes.empty?
      puts 'Result: No unused includes found'.green
    else
      puts 'Result: Found unused includes:'.red
      includes.each { |inc| puts "  - #{inc}".yellow }
      puts "Status: #{includes.size} unlinked includes detected".red
    end
  end

  def self.maintain_metadata_timestamps
    puts 'Running task: includes:maintain_metadata_timestamps'.magenta
    puts 'Status: Starting last-update metadata maintenance...'.yellow

    relationships = load_relationships
    return unless relationships

    files_processed = process_metadata_updates(relationships)

    puts "Result: Successfully updated last-update metadata in #{files_processed} files".green
    puts 'Task completed: includes:maintain_metadata_timestamps'.magenta
  end

  def self.process_metadata_updates(relationships)
    ensure_topics_have_front_matter(relationships)
    relationships['relationships'].count { |main_file, _includes| update_metadata_for(main_file) }
  end

  # Validates every existing topic up front and raises before any file is written, so a
  # topic without front matter fails the whole run rather than leaving earlier topics
  # half-updated. Reports all offenders at once.
  def self.ensure_topics_have_front_matter(relationships)
    missing = relationships['relationships'].keys.filter_map do |main_file|
      path = "#{GIT_ROOT}/help/#{main_file}"
      next unless File.exist?(path)

      front_matter, = split_front_matter(File.read(path))
      "help/#{main_file}" unless front_matter
    end
    return if missing.empty?

    raise "No front matter in: #{missing.join(', ')}; cannot write the last-update metadata key."
  end

  # Returns the date written (truthy) when the file was updated, or nil when skipped.
  def self.update_metadata_for(main_file)
    main_rel = "help/#{main_file}"
    return unless File.exist?("#{GIT_ROOT}/#{main_rel}")

    latest = rendered_change_date(main_rel)
    return unless latest

    write_last_update("#{GIT_ROOT}/#{main_rel}", latest.strftime('%Y-%m-%d'))
  end

  # Runs git from the repo root with argv (no shell), so paths and refs containing shell
  # metacharacters are passed literally rather than re-interpreted. stderr is discarded;
  # $CHILD_STATUS reflects the child's exit status afterward.
  def self.git_capture(*args)
    IO.popen(['git', '-C', GIT_ROOT, *args], err: File::NULL, &:read)
  end

  # Date the topic's reader-facing rendered output last changed on PRODUCTION_REF. The
  # walk follows that branch's first-parent history, so each step is a publish to
  # production rather than a feature branch's own integration merges, and is scoped to the
  # topic plus the includes it composes. It returns the newest publish whose expanded,
  # normalized body differs from the state just before it; edits that only touch front
  # matter or HTML comments, or that merely move already-published prose into an include
  # without changing what renders, never advance the date. nil when the topic is not yet
  # on PRODUCTION_REF (nothing has been published to readers).
  def self.rendered_change_date(main_rel)
    paths = contributing_paths(main_rel)
    shas = git_capture('log', '--first-parent', '--format=%H', PRODUCTION_REF, '--', *paths).split("\n")
    sha = shas.find { |candidate| rendered_content_changed?(candidate, main_rel) }
    sha && commit_author_date(sha)
  end

  # The topic plus the transitive set of include files it composes on PRODUCTION_REF.
  # Scoping the history walk to these paths lets an include-only edit still count as a
  # topic change.
  def self.contributing_paths(main_rel)
    paths = []
    queue = [main_rel]
    until queue.empty?
      current = queue.shift
      next if paths.include?(current)

      paths << current
      queue.concat(production_include_refs(current))
    end
    paths
  end

  # Include paths referenced directly by a file's content on PRODUCTION_REF; [] if absent.
  def self.production_include_refs(rel)
    raw = git_capture('show', "#{PRODUCTION_REF}:#{rel}")
    return [] unless $CHILD_STATUS.success?

    raw.scan(INCLUDE_DIRECTIVE).map { |match| include_rel(match.first) }
  end

  def self.rendered_content_changed?(sha, main_rel)
    rendered_body_at(sha, main_rel) != rendered_body_at("#{sha}^", main_rel)
  end

  # Reader-facing body at a git ref: front matter and HTML comments removed, {{$include}}
  # directives expanded (recursively) to the referenced file's rendered body at the same
  # ref, and whitespace collapsed. nil when the topic itself is absent at the ref.
  def self.rendered_body_at(ref, main_rel)
    raw = git_capture('show', "#{ref}:#{main_rel}")
    return nil unless $CHILD_STATUS.success?

    _front_matter, body = split_front_matter(raw)
    expand_includes(ref, body, [main_rel]).gsub(HTML_COMMENT, '').gsub(/\s+/, ' ').strip
  end

  # Recursively replaces each {{$include ...}} directive with the referenced file's body
  # at the given ref. A missing include is left untouched; already-visited paths and a
  # depth ceiling keep a cyclic include graph from looping forever.
  def self.expand_includes(ref, text, seen, depth = 0)
    return text if depth > MAX_INCLUDE_DEPTH

    text.gsub(INCLUDE_DIRECTIVE) do |directive|
      rel = include_rel(Regexp.last_match(1))
      next '' if seen.include?(rel)

      raw = git_capture('show', "#{ref}:#{rel}")
      next directive unless $CHILD_STATUS.success?

      _front_matter, body = split_front_matter(raw)
      expand_includes(ref, body, seen + [rel], depth + 1)
    end
  end

  # Turns an include directive's target (/help/_includes/foo.md) into a repo-relative path.
  def self.include_rel(directive_path)
    directive_path.strip.sub(%r{\A/}, '')
  end

  def self.commit_author_date(sha)
    output = git_capture('show', '-s', '--format=%aI', sha).strip
    return nil if output.empty?

    DateTime.parse(output).to_time
  rescue StandardError
    nil
  end

  # Surgically adds/updates only the last-update line, leaving the rest of the front
  # matter byte-for-byte intact. YAML parses the current value for an idempotent skip.
  # Front matter is guaranteed present by ensure_topics_have_front_matter; returns the
  # date written, or nil when there is nothing to change.
  def self.write_last_update(path, date)
    content = File.read(path)
    front_matter, = split_front_matter(content)
    return unless front_matter
    return if front_matter_metadata(front_matter)['last-update'].to_s == date

    File.write(path, insert_last_update(content, date))
    date
  end

  def self.front_matter_metadata(front_matter)
    YAML.safe_load(front_matter, permitted_classes: [Date, Time], aliases: true) || {}
  rescue Psych::Exception
    {}
  end

  def self.insert_last_update(content, date)
    lines = content.lines
    closing = front_matter_end(lines)
    new_line = "last-update: #{date}\n"
    existing = lines[1...closing].index { |line| line.match?(LAST_UPDATE_KEY) }

    if existing
      lines[1 + existing] = new_line
    else
      lines.insert(closing, new_line)
    end
    lines.join
  end

  # Splits a document into [front_matter_text, body]; front_matter_text is nil when absent.
  def self.split_front_matter(content)
    lines = content.lines
    closing = front_matter_end(lines)
    return [nil, content] unless closing

    [lines[1...closing].join, lines[(closing + 1)..]&.join || '']
  end

  def self.front_matter_end(lines)
    return nil unless lines[0]&.strip == '---'

    offset = lines[1..].index { |line| line.strip == '---' }
    offset && (offset + 1)
  end
end
# rubocop:enable Metrics/ModuleLength

namespace :includes do
  desc 'Maintain include-relationships.yml by discovering include relationships in markdown files.'
  task :maintain_relationships do
    IncludesTasksHelper.discover_relationships
  end

  desc 'Maintain include timestamps by adding latest include file change timestamps to main files.'
  task :maintain_timestamps do
    IncludesTasksHelper.maintain_timestamps
  end

  desc 'Add/update the last-update front matter metadata for topics with includes. The date is when ' \
       "the topic's reader-facing rendered output (its body with includes expanded) last changed on " \
       'the production first-parent history. Changes that only touch front matter or HTML comments, ' \
       'or that merely move already-published prose into an include, are ignored as invisible to end users.'
  task maintain_metadata_timestamps: :maintain_relationships do
    IncludesTasksHelper.maintain_metadata_timestamps
  end

  desc 'Maintain both include relationships and timestamps in sequence.'
  task maintain_all: %i[maintain_relationships maintain_timestamps] do
    puts 'Running task: includes:maintain_all'.magenta
    puts 'Status: Completed both relationship discovery and timestamp maintenance'.yellow
    puts 'Result: All include management tasks completed successfully'.green
    puts 'Task completed: includes:maintain_all'.magenta
  end

  desc 'Find unused includes.'
  task :unused do
    IncludesTasksHelper.find_unused_includes
  end
end
