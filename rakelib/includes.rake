# ADOBE CONFIDENTIAL
#
# Copyright 2025 Adobe All Rights Reserved.
# NOTICE:  All information contained herein is, and remains the property of Adobe and its suppliers, if any.
# The intellectual and technical concepts contained herein are proprietary to Adobe and its suppliers and are protected by all applicable intellectual property laws, including trade secret and copyright laws.
# Dissemination of this information or reproduction of this material is strictly forbidden unless prior written permission is obtained from Adobe.
#

# frozen_string_literal: true

# Include Management Tasks
# This file contains rake tasks for managing include relationships and timestamps

require 'yaml'
require 'colorator'
require 'date'
require 'tzinfo'

namespace :includes do
  # Helper method to write logs to include-relationships.log
  def log_message(message, log_file = 'include-relationships.log')
    timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
    log_entry = "[#{timestamp}] #{message}\n"
    
    # Write to log file
    File.open(log_file, 'a') do |file|
      file.write(log_entry)
    end
  end
  desc 'Maintain include-relationships.yml by discovering include relationships in markdown files.'
  task :maintain_relationships do
    log_message('Running task to maintain include-relationships.yml')
    
    relationships_file = 'include-relationships.yml'
    current_relationships = {}
    
    # Load existing relationships if file exists
    if File.exist?(relationships_file)
      current_relationships = YAML.load_file(relationships_file)
      log_message("Loaded existing relationships from #{relationships_file}")
    end
    
    # Initialize new relationships structure
    new_relationships = {
      'metadata' => {
        'last_updated' => TZInfo::Timezone.get('America/Chicago').now.strftime('%Y-%m-%d %H:%M:%S %Z'),
        'description' => 'Index of main files and their included files for automatic timestamp updates',
        'total_relationships' => 0,
        'auto_discovered' => true,
        'discovery_date' => TZInfo::Timezone.get('America/Chicago').now.strftime('%Y-%m-%d %H:%M:%S %Z')
      },
      'relationships' => {}
    }
    
    # Get list of existing include files from help/_includes directory
    include_files = Dir['../help/_includes/**/*'].select { |f| File.file?(f) && f.end_with?('.md') }
    log_message("Found #{include_files.size} include files in help/_includes directory")
    
    # Find all markdown files in the help directory (excluding _includes)
    markdown_files = Dir['../help/**/*.md'].reject { |f| f.include?('/_includes/') }
    log_message("Scanning #{markdown_files.size} main markdown files for include references...")
    
    # For each include file, search for main files that reference it
    include_files.each do |include_file|
      # Get relative path from help/_includes for searching
      include_relative_path = include_file.sub('../help/_includes/', '')
      
      # Search for files that reference this include
      referencing_files = []
      
      markdown_files.each do |main_file|
        next if File.symlink?(main_file)
        
        content = File.read(main_file)
        main_relative_path = main_file.sub('../help/', '')
        
        # Check if the main file references this include by filepath
        # Look for patterns like {{$include /help/_includes/filename.md}}
        include_pattern = /\{\{\$include\s+\/help\/_includes\/#{Regexp.escape(include_relative_path)}\}\}/
        
        if content.match?(include_pattern)
          referencing_files << main_relative_path
        end
      end
      
      if referencing_files.any?
        # Add relationships for each main file that references this include
        referencing_files.each do |main_file|
          include_absolute_path = "/help/_includes/#{include_relative_path}"
          
          if new_relationships['relationships'][main_file]
            new_relationships['relationships'][main_file] << include_absolute_path
          else
            new_relationships['relationships'][main_file] = [include_absolute_path]
          end
        end
        
        log_message("Found #{referencing_files.size} main files referencing #{include_relative_path}")
      else
        log_message("No main files reference #{include_relative_path}")
      end
    end
    
    # Count total relationships
    new_relationships['metadata']['total_relationships'] = new_relationships['relationships'].size
    
    # Write the new relationships file
    File.write(relationships_file, new_relationships.to_yaml)
    
    log_message("Updated #{relationships_file} with #{new_relationships['relationships'].size} relationships")
    
    # Show summary of changes
    if current_relationships['relationships']
      old_count = current_relationships['relationships'].size
      new_count = new_relationships['relationships'].size
      
      log_message("\nSummary:")
      log_message("  Previous relationships: #{old_count}")
      log_message("  New relationships: #{new_count}")
      
      if new_count > old_count
        log_message("  Added: #{new_count - old_count} new relationships")
      elsif new_count < old_count
        log_message("  Removed: #{old_count - new_count} relationships")
      else
        log_message("  No change in relationship count")
      end
    end
    
    log_message("\nTask completed successfully!")
  end

  desc 'Maintain include timestamps by adding latest include file change timestamps to main files.'
  task :maintain_timestamps do
    log_message('Running task to maintain include timestamps...')
    
    relationships_file = 'include-relationships.yml'
    
    unless File.exist?(relationships_file)
      log_message("Error: #{relationships_file} not found. Run 'bundle exec rake includes:maintain_relationships' first.".red)
      exit 1
    end
    
    relationships = YAML.load_file(relationships_file)
    log_message("Loaded #{relationships['relationships'].size} relationships from #{relationships_file}")
    
    # Process each main file and its includes
    relationships['relationships'].each do |main_file, includes|
      log_message("\nProcessing #{main_file}...")
      
      # Get the full path to the main file
      main_file_path = "../help/#{main_file}"
      
      unless File.exist?(main_file_path)
        log_message("  Warning: Main file #{main_file} not found, skipping")
        next
      end
      
      # Find the latest timestamp among all include files
      latest_timestamp = nil
      include_files_checked = []
      
      includes.each do |include_path|
        # Convert absolute path to relative path for git operations
        relative_include_path = include_path.sub('/help/_includes/', '../help/_includes/')
        
        # Get the latest git commit date for this include file
        # Run git from the repository root
        begin
          git_output = `git log -1 --format="%aI" -- "#{relative_include_path}" 2>/dev/null`
          if git_output.strip.empty?
            log_message("  Warning: No git history found for #{relative_include_path}")
            next
          end
          
          commit_date = DateTime.parse(git_output.strip).to_time
          include_files_checked << "#{relative_include_path} (#{commit_date.strftime('%Y-%m-%d %H:%M:%S')})"
          
          if latest_timestamp.nil? || commit_date > latest_timestamp
            latest_timestamp = commit_date
          end
        rescue => e
          log_message("  Error processing #{relative_include_path}: #{e.message}".red)
          next
        end
      end
      
      if latest_timestamp.nil?
        log_message("  Warning: Could not determine timestamp for any include files")
        next
      end
      
      log_message("  Latest include change: #{latest_timestamp.strftime('%Y-%m-%d %H:%M:%S')}")
      log_message("  Include files checked: #{include_files_checked.join(', ')}")
      
      # Read the main file content
      content = File.read(main_file_path)
      
      # Check if timestamp already exists at the end
      timestamp_pattern = /<!--\s*Last updated from includes:\s*(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\s*-->\s*$/
      
      if content.match?(timestamp_pattern)
        # Update existing timestamp
        new_content = content.sub(timestamp_pattern, "<!-- Last updated from includes: #{latest_timestamp.strftime('%Y-%m-%d %H:%M:%S')} -->\n")
        log_message("  Updated existing timestamp")
      else
        # Add new timestamp at the end
        new_content = content + "\n<!-- Last updated from includes: #{latest_timestamp.strftime('%Y-%m-%d %H:%M:%S')} -->\n"
        log_message("  Added new timestamp")
      end
      
      # Write the updated content back to the file
      File.write(main_file_path, new_content)
    end
    
    log_message("\nInclude timestamp maintenance completed successfully!")
  end

  desc 'Maintain both include relationships and timestamps in sequence.'
  task :maintain_all => [:maintain_relationships, :maintain_timestamps] do
    log_message("\nInclude maintenance completed successfully!")
  end

  desc 'Find unused includes.'
  task :unused do
    puts 'Running a task to find unused _includes'.magenta
    includes = FileList['../help/_includes/**/*']

    puts "The project contains a total of #{includes.size} includes"

    # snippets.md is expected and should not be removed based on the way the snippets functionality was designed for ExL.
    # See https://experienceleague.corp.adobe.com/docs/authoring-guide-exl/using/authoring/includes-snippets.html?lang=en#creating-snippets.
    exclude = '../help/_includes/snippets.md'
    includes.exclude(exclude) if exclude

    Dir['../help/**/*.{md}'].each do |file|
      next if File.symlink? file

      includes.delete_if { |include| File.read(file).include?(File.basename(include)) }
    end

    if includes.empty?
      puts 'No unlinked includes'.green
    else
      puts 'The following includes are not linked:'
      includes.each do |include|
        puts "No links for #{include}".yellow
      end
      puts "Found #{includes.size} unlinked includes".red
    end
  end
end
