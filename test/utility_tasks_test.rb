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

class UtilityTasksTest < Minitest::Test
  def test_available_tasks_returns_array
    tasks = AdobeComdoxExlRakeTasks::UtilityTasks.available_tasks
    assert_kind_of Array, tasks
  end

  def test_available_tasks_includes_whatsnew
    tasks = AdobeComdoxExlRakeTasks::UtilityTasks.available_tasks
    assert_includes tasks, 'whatsnew'
  end

  def test_available_tasks_includes_render
    tasks = AdobeComdoxExlRakeTasks::UtilityTasks.available_tasks
    assert_includes tasks, 'render'
  end

  def test_available_tasks_count
    tasks = AdobeComdoxExlRakeTasks::UtilityTasks.available_tasks
    assert_equal 2, tasks.size
  end
end
