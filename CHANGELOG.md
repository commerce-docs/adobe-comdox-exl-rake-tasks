# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.4.1] - 2026-07-16

### Fixed

- **`images:unused`** - Images whose Markdown alt text contains a nested `[...]` span (e.g. ExL's `[!DNL Term]` / `[!UICONTROL Term]` localization tags) were incorrectly reported as unused, since the alt-text portion of the linked-image regex stopped at the first `]` instead of the one closing the alt text itself
- **`includes:unused`** - Directories under `help/_includes/` were incorrectly reported as unused includes; only files can be referenced by `{{$include ...}}` syntax, so directories are now excluded from the candidate list
- **`includes:unused`** - Include files were matched by basename only, so two include files sharing a basename in different directories (e.g. `_includes/a/notes.md` and `_includes/b/notes.md`) could cause both to be classified as used when only one was referenced; matching is now anchored to the full `{{$include /help/_includes/<path>}}` syntax, so it requires an exact path match instead of a substring one (a shorter path like `a/notes.md` is no longer satisfied by a longer one that merely ends with it, e.g. `sub/a/notes.md`)
- **`images:unused`** - `images:svg_to_png` keeps the source SVG alongside its rendered PNG, and either file may be the one actually referenced in Markdown. An SVG was reported as unused whenever only its PNG counterpart was linked; it's now also considered used if a same-named PNG sibling is linked

## [0.4.0] - 2026-07-16

### Added

- **New task** - `images:svg_to_png` - Convert SVG images to PNG format by path (file or directory), keeping the original SVG
- **New task** - `images:check_size` - Check SVG images against the 140 KB size limit for ExL
- **Dependency** - Added `mini_magick` (~> 5.1) for SVG-to-PNG conversion
- **Test suite** - Added integration tests for the new SVG tasks and for `includes:maintain_timestamps` / `includes:maintain_all`

### Changed

- **`images:optimize`** - Now automatically runs `images:check_size` when the target path contains SVG files
- **`images:svg_to_png`** - Prefers `rsvg-convert` (librsvg) over ImageMagick's built-in SVG renderer, which takes priority over its own `rsvg-convert` delegate on many builds and fails to resolve named fonts (e.g. `font-family="Helvetica"`) in SVG text, producing an "unable to read font" error or blank text. Falls back to ImageMagick if librsvg isn't installed.
- **`images:svg_to_png`** - SVGs that embed rich text via `<foreignObject>` (e.g. draw.io/diagrams.net exports) are now rendered with headless Google Chrome or Chromium when available, since neither librsvg nor ImageMagick support `foreignObject` and would otherwise silently fall back to a truncated placeholder. Falls back to librsvg/ImageMagick with a warning if no Chromium-based browser is found.
- **`images:svg_to_png`** - Headless Chrome/Chromium is now also used as a last-resort converter for any SVG (not just `foreignObject` ones) when neither librsvg nor ImageMagick is installed, so the task works in environments that ship a browser but not the other tools (e.g. GitHub Actions' `ubuntu-latest` runners).
- **Test helper** - Replaced `reenable_task` with `reenable_all_tasks`, which reenables every defined rake task between test runs instead of only the invoked task and its declared prerequisites, fixing tasks invoked programmatically (e.g. from within `render`) not being reenabled
- **Documentation** - Corrected stale task names and examples in the README (`images:optimize`, `images:unused`, `includes:unused`) and removed a reference to a `whatsnew_bp` task that doesn't exist in the codebase

### Fixed

- **`images:svg_to_png` / `images:check_size`** - `path` can now point to a single SVG file, not just a directory. Previously `Dir["#{path}/**/*.svg"]` silently matched nothing when `path` was a file, printing "No SVG images found" even though the task's own usage example passes a file path.

## [0.3.1] - 2026-04-13

### Changed

- **Dependency** - Updated `whatsup_github` to v2.0.0
- **Dependency** - Updated `jekyll` to `~> 4.4`
- **Dev dependency** - Updated `minitest` to `~> 5.27`
- **Dev dependency** - Updated `rubocop` to `~> 1.82`

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
