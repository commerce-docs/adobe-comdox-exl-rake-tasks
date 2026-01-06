# frozen_string_literal: true

require_relative 'lib/adobe-comdox-exl-rake-tasks/version'

Gem::Specification.new do |spec|
  spec.name          = 'adobe-comdox-exl-rake-tasks'
  spec.version       = AdobeComdoxExlRakeTasks::VERSION
  spec.authors       = ['Adobe Documentation Team']
  spec.email         = ['commerce-docs@adobe.com']

  spec.summary       = 'Shared Rake tasks for Adobe documentation repositories'
  spec.description   = 'A collection of reusable Rake tasks for maintaining Adobe documentation repositories, including include relationship management, timestamp updates, and image optimization.'
  spec.homepage      = 'https://github.com/commerce-docs/adobe-comdox-exl-rake-tasks'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.3.0'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files         = Dir.glob('{lib,rakelib}/**/*') + %w[README.md LICENSE CHANGELOG.md example_usage.md]
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'colorator', '~> 1.1'
  spec.add_dependency 'date', '~> 3.3'
  spec.add_dependency 'image_optim', '~> 0.31'
  spec.add_dependency 'image_optim_pack', '~> 0.12'
  spec.add_dependency 'jekyll', '~> 4.3'
  spec.add_dependency 'rake', '~> 13.0'
  spec.add_dependency 'tzinfo', '~> 2.0'
  spec.add_dependency 'yaml', '~> 0.3'
  # whatsup_github is specified in Gemfile with git source

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'minitest', '~> 5.25'
  spec.add_development_dependency 'rubocop', '~> 1.70'
  spec.add_development_dependency 'yard', '~> 0.9'
end
