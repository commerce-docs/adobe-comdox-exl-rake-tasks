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

require 'minitest/autorun'
require 'fileutils'

# Add lib to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'adobe-comdox-exl-rake-tasks'

# Test helper module with common utilities
module TestHelper
  # Create a temporary test directory structure
  def setup_test_directory(base_path)
    FileUtils.mkdir_p(base_path)
    yield if block_given?
  end

  # Clean up temporary test directory
  def teardown_test_directory(base_path)
    FileUtils.rm_rf(base_path)
  end
end
