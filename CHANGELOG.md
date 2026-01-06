# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.3.0] - 2026-01-06

### Changed

- **Ruby version** - Updated minimum required Ruby version to `>= 3.3.0`
- **Test framework** - Replaced RSpec with Minitest for testing (35 tests, 89 assertions)
- **Code quality** - Refactored rake tasks into helper modules (`ImageTasksHelper`, `IncludesTasksHelper`) for better maintainability
- **Unused detection accuracy** - `images:unused` now detects proper Markdown (`![alt](path)`) and HTML (`<img src="path">`) image syntax instead of plain text mentions
- **Include detection accuracy** - `includes:unused` now detects proper ExL include syntax (`{{$include /help/_includes/file.md}}`) per the [Experience League Authoring Guide](https://experienceleague.adobe.com/en/docs/authoring-guide/using/markdown/markdown-syntax#snippets-and-includes)

### Added

- **Test suite** - Added comprehensive unit and integration tests using Minitest
- **Dependency** - Added `image_optim_pack` (~> 0.12) for image optimization binaries
- **Dependency** - Added `jekyll` (~> 4.3) for template rendering
- **Dependency** - Added `whatsup_github` (v1.2.0 from commerce-docs fork) for What's New digest generation
- **Embedded render task** - The `render` task no longer requires a separate `_scripts/render` file in each project

### Removed

- **Unused dependency** - Removed `json` dependency (not used in codebase)
- **Test directory** - Removed unused `test_repo` directory

## [0.2.0] - 2025-01-27

### Changed

- **Include management tasks** - Removed verbose logging for cleaner task execution
  - Simplified task output by removing comprehensive logging system
  - Tasks now run more quietly while maintaining all core functionality

## [0.1.0] - 2025-09-10

### Added

- **Initial Release** - First version of Adobe Commerce Docs in ExL Rake Tasks gem
- **Modular Rake Task Architecture**
  - Organized tasks into rakelib/ directory structure
  - `main.rake` - Core tasks and common functionality
  - `includes.rake` - Comprehensive include management tasks
  - `images.rake` - Image optimization and management tasks
- **Include Management Tasks**
  - `includes:maintain_relationships` - Automatic discovery of include relationships
  - `includes:maintain_timestamps` - Git-based timestamp updates
  - `includes:maintain_all` - Combined relationship and timestamp maintenance
  - `includes:unused` - Find unused include files
- **Image Management Tasks**
  - `images:optimize` - Optimize images in modified files
  - `images:unused` - Find unused images
- **Utility Tasks**
  - `whatsnew` - Generate data for news digest
  - `render` - Render templated files and maintain includes
- **Enhanced Documentation**
  - Comprehensive README in rakelib/ directory
  - Clear task organization and usage examples
  - Module structure with available_tasks methods
- **Dependencies**
  - `rake` - Task automation
  - `colorator` - Colorized output
  - `yaml` - YAML file handling
  - `json` - JSON processing
  - `date` - Date manipulation
  - `tzinfo` - Timezone support
  - `image_optim` - Image optimization

### Technical Details

- Modular file organization for better maintainability
- Automatic task discovery and loading from rakelib/ directory
- Comprehensive dependency management
- Better separation of concerns between task groups
- Enhanced error handling and path resolution
- Standard gem structure with proper gemspec
- Full compatibility with Adobe documentation repository workflows