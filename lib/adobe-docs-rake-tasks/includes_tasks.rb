#
# Copyright 2025 Adobe All Rights Reserved.
# NOTICE:  All information contained herein is, and remains the property of Adobe and its suppliers, if any.
# The intellectual and technical concepts contained herein are proprietary to Adobe and its suppliers and are protected by all applicable intellectual property laws, including trade secret and copyright laws.
# Dissemination of this information or reproduction of this material is strictly forbidden unless prior written permission is obtained from Adobe.
#

# frozen_string_literal: true

# Module for Adobe Comdox EXL include management tasks
module AdobeComdoxExlRakeTasks
  module IncludesTasks
    # Available tasks:
    # - includes:maintain_relationships - Discover and maintain include relationships
    # - includes:maintain_timestamps - Update timestamps based on include changes
    # - includes:maintain_all - Run both operations in sequence
    # - includes:unused - Find unused include files
    
    def self.available_tasks
      %w[
        includes:maintain_relationships
        includes:maintain_timestamps
        includes:maintain_all
        includes:unused
      ]
    end
  end
end
