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

require_relative 'test_helper'
require 'rake'
require 'yaml'
require 'fileutils'

# Load rake tasks once at require time
GEM_ROOT = File.expand_path('../..', __dir__)
Dir[File.join(GEM_ROOT, 'rakelib', '*.rake')].each { |f| load f }

# Integration test helper for running actual rake tasks
module IntegrationTestHelper
  TEMP_DIR = File.expand_path('../tmp/test_workspace', __dir__)

  def setup_test_workspace
    FileUtils.rm_rf(TEMP_DIR)
    FileUtils.mkdir_p(TEMP_DIR)
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'help'))
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'help', '_includes'))
    FileUtils.mkdir_p(File.join(TEMP_DIR, '_data'))
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'rakelib'))
  end

  def teardown_test_workspace
    FileUtils.rm_rf(TEMP_DIR)
  end

  def create_test_file(relative_path, content)
    full_path = File.join(TEMP_DIR, relative_path)
    FileUtils.mkdir_p(File.dirname(full_path))
    File.write(full_path, content)
    full_path
  end

  def read_test_file(relative_path)
    File.read(File.join(TEMP_DIR, relative_path))
  end

  def file_exists?(relative_path)
    File.exist?(File.join(TEMP_DIR, relative_path))
  end

  def run_task_in_workspace(task_name)
    original_dir = Dir.pwd
    Dir.chdir(File.join(TEMP_DIR, 'rakelib'))

    capture_task_output(task_name)
  ensure
    Dir.chdir(original_dir)
  end

  private

  def capture_task_output(task_name)
    output = StringIO.new
    with_captured_stdout(output) { invoke_task(task_name, output) }
    output.string
  end

  def with_captured_stdout(output)
    original_stdout = $stdout
    $stdout = output
    yield
  ensure
    $stdout = original_stdout
  end

  def invoke_task(task_name, output)
    reenable_all_tasks
    Rake::Task[task_name].invoke
  rescue StandardError => e
    output.puts "Error: #{e.message}"
  end

  # Reenable every defined task, not just task_name and its declared
  # prerequisites: some tasks (e.g. render) invoke other tasks manually from
  # within their action rather than declaring them as prerequisites, so a
  # narrower reenable misses them once they've already run once in the suite.
  def reenable_all_tasks
    Rake::Task.tasks.each(&:reenable)
  end
end
