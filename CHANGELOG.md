# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2025-01-27

### Added

- **Enhanced Logging System** - Comprehensive logging functionality for include management tasks
  - Added `log_message` helper method for timestamped logging
  - All include management tasks now write detailed logs to `include-relationships.log`
  - Improved debugging and task execution tracking
  - Timestamped log entries with consistent format

### Changed

- **Include Management Tasks** - Enhanced with comprehensive logging
  - `includes:maintain_relationships` now logs all discovery and processing steps
  - `includes:maintain_timestamps` provides detailed logging of timestamp updates
  - `includes:maintain_all` includes logging for combined operations
  - All console output now also written to log file for better traceability

### Technical Details

- Log file format: `[YYYY-MM-DD HH:MM:SS] message`
- Log file location: `include-relationships.log` (in project root)
- Maintains backward compatibility with existing console output
- Enhanced error tracking and debugging capabilities

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