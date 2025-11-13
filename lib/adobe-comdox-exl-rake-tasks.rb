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

# Adobe Commerce Docs in ExL Rake Tasks Gem
# This gem provides shared Rake tasks for Adobe Experience League documentation repositories

require 'rake'

# Load all module files
require_relative 'adobe-comdox-exl-rake-tasks/version'
require_relative 'adobe-comdox-exl-rake-tasks/includes_tasks'
require_relative 'adobe-comdox-exl-rake-tasks/image_tasks'
require_relative 'adobe-comdox-exl-rake-tasks/utility_tasks'

# Load all shared Rake tasks from rakelib directory
Dir[File.join(__dir__, '..', 'rakelib', '*.rake')].each do |rake_file|
  load rake_file
end
