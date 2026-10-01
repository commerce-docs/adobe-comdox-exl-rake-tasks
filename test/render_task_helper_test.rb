# frozen_string_literal: true

require_relative 'integration_test_helper'

class RenderTaskHelperTest < Minitest::Test
  include IntegrationTestHelper

  def setup
    setup_test_workspace
  end

  def teardown
    teardown_test_workspace
  end

  def test_defaults_without_repository_config
    create_rendered_template('_jekyll')

    output = render_from('rakelib')

    assert_includes output, 'Templates rendered successfully.'
    assert_equal 'Rendered content', read_test_file('help/_includes/templated/example.md')
  end

  def test_defaults_from_repository_root_with_empty_config
    create_test_file('_config.yml', '')
    create_rendered_template('_jekyll')

    render_from('.')

    assert file_exists?('help/_includes/templated/example.md')
  end

  def test_custom_helper_directory_with_default_destination
    create_test_file('_config.yml', "helper_dir: custom-helper\n")
    create_rendered_template('custom-helper')
    create_test_file('custom-helper/_config.yml', 'helper_dir: ignored')

    render_from('rakelib')

    assert file_exists?('help/_includes/templated/example.md')
    refute file_exists?('_jekyll/_site/templated/example.md')
  end

  def test_custom_destination_with_default_helper_directory
    create_test_file('_config.yml', "templated_dest: help/_includes/custom\n")
    create_rendered_template('_jekyll')

    output = render_from('rakelib')

    assert file_exists?('help/_includes/custom/example.md')
    refute file_exists?('help/_includes/templated/example.md')
    assert_includes output, File.join(TEMP_DIR, 'help/_includes/custom')
  end

  def test_relative_overrides_from_repository_root
    create_test_file('_config.yml', "helper_dir: helper\ntemplated_dest: output\n")
    create_rendered_template('helper')

    render_from('.')

    assert_equal 'Rendered content', read_test_file('output/example.md')
  end

  def test_absolute_overrides
    create_test_file('_config.yml', {
      'helper_dir' => File.join(TEMP_DIR, 'helper'),
      'templated_dest' => File.join(TEMP_DIR, 'output')
    }.to_yaml)
    create_rendered_template('helper')

    render_from('rakelib')

    assert file_exists?('output/example.md')
  end

  def test_configuration_is_reloaded_for_each_render
    create_rendered_template('_jekyll')
    render_from('rakelib')
    create_test_file('_config.yml', "helper_dir: helper\ntemplated_dest: output\n")
    create_rendered_template('helper')

    render_from('rakelib')

    assert file_exists?('output/example.md')
  end

  def test_configuration_supports_yaml_dates_and_aliases
    create_test_file('_config.yml', <<~YAML)
      updated: 2026-10-01
      published: 2026-10-01 12:00:00 Z
      helper_dir: &helper helper
      other_directory: *helper
      templated_dest: output
    YAML
    create_rendered_template('helper')

    render_from('rakelib')

    assert file_exists?('output/example.md')
  end

  def test_configuration_requires_a_mapping
    create_test_file('_config.yml', '- not a mapping')

    error = assert_raises(ArgumentError) do
      Dir.chdir(TEMP_DIR) { RenderTaskHelper.configure_paths }
    end

    assert_includes error.message, 'must contain a YAML mapping'
  end

  def test_configured_paths_require_non_empty_strings
    %w[helper_dir templated_dest].each do |key|
      [nil, '', '   ', 42, []].each do |value|
        create_test_file('_config.yml', { key => value }.to_yaml)

        error = assert_raises(ArgumentError) do
          Dir.chdir(TEMP_DIR) { RenderTaskHelper.configure_paths }
        end

        assert_includes error.message, "#{key} in _config.yml must be a non-empty string"
      end
    end
  end

  private

  def create_rendered_template(helper_dir)
    create_test_file("#{helper_dir}/_site/templated/example.html", 'Rendered content')
  end

  def render_from(relative_dir)
    Dir.chdir(File.join(TEMP_DIR, relative_dir)) do
      RenderTaskHelper.stub(:system, true) do
        capture_io { RenderTaskHelper.render_templates }.first
      end
    end
  end
end
