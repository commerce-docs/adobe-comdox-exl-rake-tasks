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

  def test_defaults_without_configuration
    create_rendered_template('rakelib')

    output = render_from('rakelib')

    assert_includes output, 'Templates rendered successfully.'
    assert_equal 'Rendered content', read_test_file('rakelib/help/_includes/templated/example.md')
  end

  def test_defaults_from_current_directory_with_empty_config
    create_test_file('_config.yml', '')
    create_rendered_template('.')

    render_from('.')

    assert file_exists?('help/_includes/templated/example.md')
  end

  def test_helper_dir_configuration_is_ignored
    create_test_file('_helper/_config.yml', "helper_dir: nonexistent\n")
    create_rendered_template('_helper')

    render_from('_helper')

    assert file_exists?('_helper/help/_includes/templated/example.md')
    refute file_exists?('nonexistent/_site/templated/example.md')
  end

  def test_custom_destination_uses_current_directory_configuration
    create_test_file('_config.yml', "templated_dest: ignored\n")
    create_test_file('rakelib/_config.yml', "templated_dest: ../help/_includes/custom\n")
    create_rendered_template('rakelib')

    output = render_from('rakelib')

    assert file_exists?('help/_includes/custom/example.md')
    refute file_exists?('help/_includes/templated/example.md')
    refute file_exists?('ignored/example.md')
    assert_includes output, File.join(TEMP_DIR, 'help/_includes/custom')
  end

  def test_relative_destination_from_helper_directory
    create_test_file('_helper/_config.yml', "templated_dest: ../src/pages/_includes/templated\n")
    create_rendered_template('_helper')

    render_from('_helper')

    assert_equal 'Rendered content', read_test_file('src/pages/_includes/templated/example.md')
  end

  def test_absolute_destination
    create_test_file('rakelib/_config.yml', {
      'templated_dest' => File.join(TEMP_DIR, 'output')
    }.to_yaml)
    create_rendered_template('rakelib')

    render_from('rakelib')

    assert file_exists?('output/example.md')
  end

  def test_configuration_is_reloaded_for_each_render
    create_rendered_template('rakelib')
    render_from('rakelib')
    create_test_file('_helper/_config.yml', "templated_dest: ../output\n")
    create_rendered_template('_helper')

    render_from('_helper')

    assert file_exists?('output/example.md')
  end

  def test_configuration_supports_yaml_dates_and_aliases
    create_test_file('rakelib/_config.yml', <<~YAML)
      updated: 2026-10-01
      published: 2026-10-01 12:00:00 Z
      templated_dest: &destination ../output
      other_directory: *destination
    YAML
    create_rendered_template('rakelib')

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

  def test_destination_requires_a_non_empty_string
    [nil, '', '   ', 42, []].each do |value|
      create_test_file('_config.yml', { 'templated_dest' => value }.to_yaml)

      error = assert_raises(ArgumentError) do
        Dir.chdir(TEMP_DIR) { RenderTaskHelper.configure_paths }
      end

      assert_includes error.message, 'templated_dest in _config.yml must be a non-empty string'
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
