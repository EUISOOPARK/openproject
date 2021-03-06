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

begin
  require 'mocha/setup'
rescue
  # Won't run some tests
end

class AccountTest < ActionDispatch::IntegrationTest
  fixtures :all

  # Replace this with your real tests.
  def test_login
    get "my/page"
    assert_redirected_to "/login?back_url=http%3A%2F%2Fwww.example.com%2Fmy%2Fpage"
    log_user('jsmith', 'jsmith')

    get "my/account"
    assert_response :success
    assert_template "my/account"
  end

  def test_redirect_after_login
    target_url =  "/my/account?q=%C3%A4"

    get target_url
    post @response.redirect_url, :username => 'jsmith', :password => 'jsmith'

    assert_redirected_to target_url
  end

  def test_autologin
    user = User.find(1)
    Setting.autologin = "7"
    Token.delete_all

    # User logs in with 'autologin' checked
    post '/login', :username => user.login, :password => 'adminADMIN!', :autologin => 1
    assert_redirected_to '/my/page'
    token = Token.find :first
    assert_not_nil token
    assert_equal user, token.user
    assert_equal 'autologin', token.action
    assert_equal user.id, session[:user_id]
    assert_equal token.value, cookies[Redmine::Configuration['autologin_cookie_name']]

    # Session is cleared
    reset!
    User.current = nil
    # Clears user's last login timestamp
    user.update_attribute :last_login_on, nil
    assert_nil user.reload.last_login_on

    # User comes back with his autologin cookie
    cookies[Redmine::Configuration['autologin_cookie_name']] = token.value
    get '/my/page'
    assert_response :success
    assert_template 'my/page'
    assert_equal user.id, session[:user_id]
    assert_not_nil user.reload.last_login_on
    assert user.last_login_on.utc > 20.second.ago.utc
  end

  def test_lost_password
    Token.delete_all

    get "account/lost_password"
    assert_response :success
    assert_template "account/lost_password"

    post "account/lost_password", :mail => 'jSmith@somenet.foo'
    assert_redirected_to "/login?back_url=http%3A%2F%2Fwww.example.com%2F"

    token = Token.find(:first)
    assert_equal 'recovery', token.action
    assert_equal 'jsmith@somenet.foo', token.user.mail
    assert !token.expired?

    get "account/lost_password", :token => token.value
    assert_response :success
    assert_template "account/password_recovery"

    post "account/lost_password", :token => token.value, :new_password => 'newpassPASS!', :new_password_confirmation => 'newpassPASS!'
    assert_redirected_to "/login"
    assert_equal 'Password was successfully updated.', flash[:notice]

    log_user('jsmith', 'newpassPASS!')
    assert_equal 0, Token.count
  end

  should_eventually "login after losing password should redirect back to home" do
    visit "/login"
    assert_response :success

    click_link "Lost password"
    assert_response :success

    # Lost password form
    fill_in "mail", :with => "admin@somenet.foo"
    click_button "Submit"

    assert_response :success # back to login page
    assert_equal "/login", current_path

    fill_in "Login:", :with => 'admin'
    fill_in "Password:", :with => 'test'
    click_button "login"

    assert_response :success
    assert_equal "/", current_path

  end


  if Object.const_defined?(:Mocha)

  def test_onthefly_registration
    # disable registration
    Setting.self_registration = '0'
    AuthSource.expects(:authenticate).returns({:login => 'foo', :firstname => 'Foo', :lastname => 'Smith', :mail => 'foo@bar.com', :auth_source_id => 66})

    post 'account/login', :username => 'foo', :password => 'bar'
    assert_redirected_to '/my/first_login'

    user = User.find_by_login('foo')
    assert user.is_a?(User)
    assert_equal 66, user.auth_source_id
    assert user.current_password.nil?
  end

  else
    puts 'Mocha is missing. Skipping tests.'
  end
end
