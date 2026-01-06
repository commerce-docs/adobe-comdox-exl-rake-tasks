# frozen_string_literal: true

source 'https://rubygems.org'

# Specify your gem's dependencies in adobe-comdox-exl-rake-tasks.gemspec
gemspec

# Runtime dependencies with git sources (can't be specified in gemspec)
gem 'whatsup_github', git: 'https://github.com/commerce-docs/whatsup_github', tag: 'v1.2.0'

# Additional dependencies for development and testing
gem 'tzinfo', '~> 2.0'

group :development do
  gem 'minitest', '~> 5.25'
  gem 'rake', '~> 13.0'
  gem 'rubocop', '~> 1.70'
  gem 'yard', '~> 0.9'
end
