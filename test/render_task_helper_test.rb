# frozen_string_literal: true

require_relative 'integration_test_helper'

class RenderTaskHelperTest < Minitest::Test
  include IntegrationTestHelper

  def setup
    setup_test_workspace
    assert system('git', '-C', TEMP_DIR, 'init', '--quiet', out: File::NULL, err: File::NULL)
  end

  def teardown
    teardown_test_workspace
  end

  def test_help_destination_from_helper_directory_without_configuration
    create_rendered_template('rakelib')

    output = render_from('rakelib')

    assert_includes output, 'Templates rendered successfully.'
    assert_equal 'Rendered content', read_test_file('help/_includes/templated/example.md')
    refute file_exists?('rakelib/help/_includes/templated/example.md')
    assert file_exists?('rakelib/_site/templated/example.md')
    refute file_exists?('rakelib/_site/templated/example.html')
  end

  def test_help_destination_from_repository_root_with_empty_config
    create_test_file('_config.yml', '')
    create_rendered_template('.')

    render_from('.')

    assert file_exists?('help/_includes/templated/example.md')
  end

  def test_helper_dir_configuration_is_ignored
    create_test_file('_helper/_config.yml', "helper_dir: nonexistent\n")
    create_rendered_template('_helper')

    render_from('_helper')

    assert file_exists?('help/_includes/templated/example.md')
    refute file_exists?('nonexistent/_site/templated/example.md')
  end

  def test_destination_configuration_is_ignored
    create_test_file('_config.yml', "templated_dest: ignored\n")
    create_test_file('rakelib/_config.yml', "templated_dest: ../help/_includes/custom\n")
    create_rendered_template('rakelib')

    output = render_from('rakelib')

    assert file_exists?('help/_includes/templated/example.md')
    refute file_exists?('help/_includes/custom/example.md')
    refute file_exists?('ignored/example.md')
    assert_includes output, File.join(TEMP_DIR, 'help/_includes/templated')
  end

  def test_src_pages_destination_from_nested_helper_directory
    FileUtils.rm_rf(File.join(TEMP_DIR, 'help'))
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'src/pages'))
    create_rendered_template('tools/_helper')

    render_from('tools/_helper')

    assert_equal 'Rendered content', read_test_file('src/pages/_includes/templated/example.md')
    refute file_exists?('help/_includes/templated/example.md')
  end

  def test_src_pages_takes_precedence_when_both_layouts_exist
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'src/pages'))
    create_rendered_template('.')

    render_from('.')

    assert file_exists?('src/pages/_includes/templated/example.md')
    refute file_exists?('help/_includes/templated/example.md')
  end

  def test_destination_is_detected_for_each_render
    create_rendered_template('rakelib')
    render_from('rakelib')
    FileUtils.mkdir_p(File.join(TEMP_DIR, 'src/pages'))
    create_rendered_template('_helper')

    render_from('_helper')

    assert file_exists?('src/pages/_includes/templated/example.md')
  end

  def test_render_helper_does_not_parse_jekyll_configuration
    create_test_file('rakelib/_config.yml', '- not a mapping')
    create_rendered_template('rakelib')

    render_from('rakelib')

    assert file_exists?('help/_includes/templated/example.md')
  end

  def test_missing_layout_fails_before_building_or_copying
    FileUtils.rm_rf(File.join(TEMP_DIR, 'help'))
    create_rendered_template('rakelib')

    error = assert_raises(ArgumentError) do
      RenderTaskHelper.stub(:system, ->(*) { flunk 'Jekyll must not run without a supported layout' }) do
        render_without_stubs('rakelib')
      end
    end

    assert_includes error.message, 'src/pages or help/_includes'
    assert file_exists?('rakelib/_site/templated/example.html')
    refute file_exists?('help/_includes/templated')
  end

  def test_regular_files_do_not_count_as_layout_directories
    FileUtils.rm_rf(File.join(TEMP_DIR, 'help/_includes'))
    create_test_file('help/_includes', 'not a directory')
    create_test_file('src/pages', 'not a directory')

    assert_raises(ArgumentError) do
      Dir.chdir(TEMP_DIR) { RenderTaskHelper.configure_paths }
    end
  end

  def test_git_root_failure_has_a_clear_error
    IO.stub(:popen, ->(*) { '' }) do
      error = assert_raises(ArgumentError) do
        Dir.chdir(TEMP_DIR) { RenderTaskHelper.configure_paths }
      end

      assert_includes error.message, 'Cannot determine the Git repository root'
    end
  end

  def test_missing_git_has_a_clear_error
    IO.stub(:popen, ->(*) { raise Errno::ENOENT, 'git' }) do
      error = assert_raises(ArgumentError) do
        Dir.chdir(TEMP_DIR) { RenderTaskHelper.configure_paths }
      end

      assert_includes error.message, 'Git is required'
    end
  end

  private

  def create_rendered_template(helper_dir)
    create_test_file("#{helper_dir}/_site/templated/example.html", 'Rendered content')
  end

  def render_from(relative_dir)
    RenderTaskHelper.stub(:system, true) do
      render_without_stubs(relative_dir)
    end
  end

  def render_without_stubs(relative_dir)
    Dir.chdir(File.join(TEMP_DIR, relative_dir)) do
      capture_io { RenderTaskHelper.render_templates }.first
    end
  end
end
