#
# Copyright 2025 Adobe All Rights Reserved.
# NOTICE:  All information contained herein is, and remains the property of Adobe and its suppliers, if any.
# The intellectual and technical concepts contained herein are proprietary to Adobe and its suppliers and are protected by all applicable intellectual property laws, including trade secret and copyright laws.
# Dissemination of this information or reproduction of this material is strictly forbidden unless prior written permission is obtained from Adobe.
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
