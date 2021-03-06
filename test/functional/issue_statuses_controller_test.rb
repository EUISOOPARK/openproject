#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
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
#
# See doc/COPYRIGHT.rdoc for more details.
#++

require File.expand_path('../../test_helper', __FILE__)
require 'issue_statuses_controller'

# Re-raise errors caught by the controller.
class IssueStatusesController; def rescue_action(e) raise e end; end


class IssueStatusesControllerTest < ActionController::TestCase
  fixtures :all

  def setup
    super
    @controller = IssueStatusesController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end

  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end

  def test_new
    get :new
    assert_response :success
    assert_template 'new'
  end

  def test_create
    assert_difference 'IssueStatus.count' do
      post :create, :issue_status => {:name => 'New status'}
    end
    assert_redirected_to :action => 'index'
    status = IssueStatus.find(:first, :order => 'id DESC')
    assert_equal 'New status', status.name
  end

  def test_edit
    get :edit, :id => '3'
    assert_response :success
    assert_template 'edit'
  end

  def test_update
    post :update, :id => '3', :issue_status => {:name => 'Renamed status'}
    assert_redirected_to :action => 'index'
    status = IssueStatus.find(3)
    assert_equal 'Renamed status', status.name
  end

  def test_destroy
    WorkPackage.delete_all("status_id = 1")

    assert_difference 'IssueStatus.count', -1 do
      post :destroy, :id => '1'
    end
    assert_redirected_to :action => 'index'
    assert_nil IssueStatus.find_by_id(1)
  end

  def test_destroy_should_block_if_status_in_use
    assert_not_nil WorkPackage.find_by_status_id(1)

    assert_no_difference 'IssueStatus.count' do
      post :destroy, :id => '1'
    end
    assert_redirected_to :action => 'index'
    assert_not_nil IssueStatus.find_by_id(1)
  end

  context "on POST to :update_work_package_done_ratio" do
    context "with Setting.work_package_done_ratio using the issue_field" do
      setup do
        Setting.work_package_done_ratio = 'issue_field'
        post :update_issue_done_ratio
      end

      should set_the_flash.to /not updated/
      should redirect_to('the index') { '/issue_statuses' }
    end

    context "with Setting.work_package_done_ratio using the issue_status" do
      setup do
        Setting.work_package_done_ratio = 'issue_status'
        post :update_issue_done_ratio
      end

      should set_the_flash.to /Work package done ratios updated/
      should redirect_to('the index') { '/issue_statuses' }
    end
  end

end
