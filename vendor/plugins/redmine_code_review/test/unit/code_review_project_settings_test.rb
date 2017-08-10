# Code Review plugin for Redmine
# Copyright (C) 2010  Haruyuki Iida
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
require File.dirname(__FILE__) + '/../test_helper'

class CodeReviewProjectSettingsTest < ActiveSupport::TestCase
  fixtures :code_review_project_settings, :projects, :users, :trackers

  # Replace this with your real tests.
  context "save" do
    setup do
      @setting = CodeReviewProjectSetting.new
    end

    should "return false if project_id is nil." do      
      assert !@setting.save
    end

    should "return true if project_id is setted." do
      @setting.project_id = 1
      @setting.tracker_id = 1
      @setting.assignment_tracker_id = 1
      assert @setting.save
    end
  end

  context "auto_assign" do
    setup do
      CodeReviewProjectSetting.destroy_all
    end

    should "be saved if auto_assign is setted." do
      setting = CodeReviewProjectSetting.generate!(:project_id => 1, :tracker_id => 1)
      id = setting.id
      assert !setting.auto_assign_settings.enabled?
      setting.auto_assign_settings.enabled = true
      assert setting.save
      setting = CodeReviewProjectSetting.find(id)
      assert setting.auto_assign_settings.enabled?
    end
  end
end
