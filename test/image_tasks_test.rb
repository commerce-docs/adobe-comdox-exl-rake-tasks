# MIT License
#
# Copyright (c) 2025 Adobe Inc.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

# frozen_string_literal: true

require_relative 'test_helper'

class ImageTasksTest < Minitest::Test
  def test_available_tasks_returns_array
    tasks = AdobeComdoxExlRakeTasks::ImageTasks.available_tasks
    assert_kind_of Array, tasks
  end

  def test_available_tasks_includes_optimize
    tasks = AdobeComdoxExlRakeTasks::ImageTasks.available_tasks
    assert_includes tasks, 'images:optimize'
  end

  def test_available_tasks_includes_unused
    tasks = AdobeComdoxExlRakeTasks::ImageTasks.available_tasks
    assert_includes tasks, 'images:unused'
  end

  def test_available_tasks_includes_svg_to_png
    tasks = AdobeComdoxExlRakeTasks::ImageTasks.available_tasks
    assert_includes tasks, 'images:svg_to_png'
  end

  def test_available_tasks_includes_check_size
    tasks = AdobeComdoxExlRakeTasks::ImageTasks.available_tasks
    assert_includes tasks, 'images:check_size'
  end

  def test_available_tasks_count
    tasks = AdobeComdoxExlRakeTasks::ImageTasks.available_tasks
    assert_equal 4, tasks.size
  end

  def test_image_linked_with_dnl_tag_in_alt_text
    content = '![[!DNL RabbitMQ] node status](../../assets/tools/rabbitmq-tab-4.jpeg)'
    assert ImageTasksHelper.image_linked?(content, 'rabbitmq-tab-4.jpeg')
  end

  def test_image_linked_with_uicontrol_tag_in_alt_text
    content = '![Click [!UICONTROL Save]](../assets/save-button.png)'
    assert ImageTasksHelper.image_linked?(content, 'save-button.png')
  end

  def test_image_linked_with_dnl_tag_mid_alt_text
    content = '![Simple [!DNL Varnish] Configuration](../assets/single-varnish.png)'
    assert ImageTasksHelper.image_linked?(content, 'single-varnish.png')
  end

  def test_image_linked_returns_false_when_basename_absent
    content = '![Simple [!DNL Varnish] Configuration](../assets/single-varnish.png)'
    refute ImageTasksHelper.image_linked?(content, 'other-image.png')
  end

  def test_svg_png_counterpart_used_when_png_sibling_is_linked
    Dir.mktmpdir do |dir|
      svg = File.join(dir, 'diagram.svg')
      File.write(File.join(dir, 'diagram.png'), 'fake png content')
      File.write(svg, 'fake svg content')

      contents = ['![Diagram](assets/diagram.png)']
      assert ImageTasksHelper.svg_png_counterpart_used?(svg, contents)
    end
  end

  def test_svg_png_counterpart_used_returns_false_without_png_sibling
    Dir.mktmpdir do |dir|
      svg = File.join(dir, 'diagram.svg')
      File.write(svg, 'fake svg content')

      contents = ['![Diagram](assets/diagram.png)']
      refute ImageTasksHelper.svg_png_counterpart_used?(svg, contents)
    end
  end

  def test_svg_png_counterpart_used_returns_false_when_png_sibling_unused
    Dir.mktmpdir do |dir|
      svg = File.join(dir, 'diagram.svg')
      File.write(File.join(dir, 'diagram.png'), 'fake png content')
      File.write(svg, 'fake svg content')

      contents = ['Just text content, no images.']
      refute ImageTasksHelper.svg_png_counterpart_used?(svg, contents)
    end
  end

  def test_svg_png_counterpart_used_returns_false_for_non_svg_image
    Dir.mktmpdir do |dir|
      png = File.join(dir, 'diagram.png')
      File.write(png, 'fake png content')

      contents = ['![Diagram](assets/diagram.png)']
      refute ImageTasksHelper.svg_png_counterpart_used?(png, contents)
    end
  end
end
