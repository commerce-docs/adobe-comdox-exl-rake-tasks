# Adobe Commerce Docs in ExL Rake Tasks

A collection of reusable Rake tasks for maintaining Adobe Experience League documentation repositories. This gem provides standardized tools for managing include relationships, timestamps, images, and other common documentation maintenance tasks.

## Features

- **Include Management**: Automatically discover and maintain include file relationships
- **Timestamp Updates**: Keep main files updated with latest include file changes
- **What's New Generation**: Generate news digests from GitHub activity
- **Image Optimization**: Find and optimize unused images
- **Include Auditing**: Identify orphaned include files
- **Utility Tasks**: Template rendering and task management

## Installation

Add this line to your repository's `Gemfile`:

```ruby
gem 'adobe-comdox-exl-rake-tasks', git: 'https://github.com/commerce-docs/adobe-comdox-exl-rake-tasks.git'
```

Then execute:

```bash
bundle install
```

## Usage

Once installed, all tasks are automatically available in your repository.

### Include Management

Maintain include file relationships and timestamps:

```bash
# Discover and maintain include relationships
bundle exec rake includes:maintain_relationships

# Update timestamps in main files
bundle exec rake includes:maintain_timestamps

# Run both tasks in sequence
bundle exec rake includes:maintain_all
```

### What's New Generation

Generate news digests from GitHub activity:

```bash
# Generate What's New digest since last update
bundle exec rake whatsnew

# Generate Best Practices What's New digest
bundle exec rake whatsnew_bp

# Generate for specific time period
bundle exec rake whatsnew since="jul 4"
```

### Image Management

Optimize and audit images:

```bash
# Optimize images in modified files
bundle exec rake image_optim

# Find unused images
bundle exec rake unused_images

# Find unused include files
bundle exec rake unused_includes
```

### Utility Tasks

```bash
# Render templated files
bundle exec rake render

# Show task help
bundle exec rake -T
```

## Configuration

The gem automatically detects your repository structure and works with the standard Adobe docs layout:

```
repository/
├── help/
│   ├── _includes/          # Include files
│   └── *.md               # Main documentation files
├── include-relationships.yml  # Generated relationships file
└── Rakefile               # Your main Rakefile
```

## Development

### Building the Gem

```bash
gem build adobe-comdox-exl-rake-tasks.gemspec
```

### Installing Locally

```bash
gem install ./adobe-comdox-exl-rake-tasks-0.1.0.gem
```

### Running Tests

```bash
bundle exec rspec
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For issues and questions, please open an issue on the GitHub repository or contact the Adobe Documentation Team.
