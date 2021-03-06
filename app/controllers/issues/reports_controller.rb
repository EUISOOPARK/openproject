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

class Issues::ReportsController < ApplicationController
  menu_item :summary_field, :only => [:report, :report_details]
  before_filter :find_project_by_project_id, :authorize, :find_issue_statuses

  def report
    @types = @project.types
    @versions = @project.shared_versions.sort
    @priorities = IssuePriority.all
    @categories = @project.issue_categories
    @assignees = @project.members.collect { |m| m.user }.sort
    @authors = @project.members.collect { |m| m.user }.sort
    @subprojects = @project.descendants.visible

    @issues_by_type = WorkPackage.by_type(@project)
    @issues_by_version = WorkPackage.by_version(@project)
    @issues_by_priority = WorkPackage.by_priority(@project)
    @issues_by_category = WorkPackage.by_category(@project)
    @issues_by_assigned_to = WorkPackage.by_assigned_to(@project)
    @issues_by_author = WorkPackage.by_author(@project)
    @issues_by_subproject = WorkPackage.by_subproject(@project) || []
  end

  def report_details
    case params[:detail]
    when "type"
      @field = "type_id"
      @rows = @project.types
      @data = WorkPackage.by_type(@project)
      @report_title = WorkPackage.human_attribute_name(:type)
    when "version"
      @field = "fixed_version_id"
      @rows = @project.shared_versions.sort
      @data = WorkPackage.by_version(@project)
      @report_title = WorkPackage.human_attribute_name(:version)
    when "priority"
      @field = "priority_id"
      @rows = IssuePriority.all
      @data = WorkPackage.by_priority(@project)
      @report_title = WorkPackage.human_attribute_name(:priority)
    when "category"
      @field = "category_id"
      @rows = @project.issue_categories
      @data = WorkPackage.by_category(@project)
      @report_title = WorkPackage.human_attribute_name(:category)
    when "assigned_to"
      @field = "assigned_to_id"
      @rows = @project.members.collect { |m| m.user }.sort
      @data = WorkPackage.by_assigned_to(@project)
      @report_title = WorkPackage.human_attribute_name(:assigned_to)
    when "author"
      @field = "author_id"
      @rows = @project.members.collect { |m| m.user }.sort
      @data = WorkPackage.by_author(@project)
      @report_title = WorkPackage.human_attribute_name(:author)
    when "subproject"
      @field = "project_id"
      @rows = @project.descendants.visible
      @data = WorkPackage.by_subproject(@project) || []
      @report_title = l(:label_subproject_plural)
    end

    respond_to do |format|
      if @field
        format.html {}
      else
        format.html { redirect_to report_project_issues_path(@project) }
      end
    end
  end

  private

  def find_issue_statuses
    @statuses = IssueStatus.find(:all, :order => 'position')
  end

  def default_breadcrumb
    l(:label_summary)
  end
end
