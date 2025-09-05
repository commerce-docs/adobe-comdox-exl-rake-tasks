# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "adobe-comdox-exl-rake-tasks"
  spec.version       = "0.1.0"
  spec.authors       = ["Adobe Documentation Team"]
  spec.email         = ["docs@adobe.com"]

  spec.summary       = "Shared Rake tasks for Adobe documentation repositories"
  spec.description   = "A collection of reusable Rake tasks for maintaining Adobe documentation repositories, including include relationship management, timestamp updates, and image optimization."
  spec.homepage      = "https://github.com/commerce-docs/adobe-comdox-exl-rake-tasks"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 2.7.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files         = Dir.glob("{lib,rakelib}/**/*") + %w[README.md LICENSE CHANGELOG.md example_usage.md]
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rake", ">= 13.0"
  spec.add_dependency "colorator", "~> 1.1"
  spec.add_dependency "yaml", "~> 0.2"
  spec.add_dependency "json", "~> 2.6"
  spec.add_dependency "date", "~> 3.2"
  spec.add_dependency "tzinfo", "~> 2.0"
  spec.add_dependency "image_optim", "~> 0.30"

  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.50"
  spec.add_development_dependency "yard", "~> 0.9"
end
