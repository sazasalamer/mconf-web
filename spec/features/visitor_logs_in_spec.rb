# This file is part of Mconf-Web, a web application that provides access
# to the Mconf webconferencing system. Copyright (C) 2010-2015 Mconf.
#
# This file is licensed under the Affero General Public License version
# 3 or later. See the LICENSE file.

require 'spec_helper'

feature 'Visitor logs in' do
  before(:each) {
    @user = FactoryGirl.create(:user, :username => 'user-1', :password => 'password')
    page.driver.header 'Referer', "http://#{Site.current.domain}"
  }

  scenario 'with valid email and password' do
    sign_in_with @user.email, @user.password

    expect(page).to have_title(I18n.t('home.my'))
    expect(current_path).to eq(my_home_path)
  end

  scenario 'with valid username and password' do
    sign_in_with @user.username, @user.password

    expect(page).to have_title(I18n.t('home.my'))
    expect(current_path).to eq(my_home_path)
  end

  scenario 'with invalid email' do
    sign_in_with 'invalid_email', @user.password

    expect(current_path).to eq(new_user_session_path)
    expect(page).to have_content 'Invalid email or password'
  end

  feature 'with valid credentials' do
    scenario 'from /login' do
      visit login_path

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario 'from /users/login' do
      visit new_user_session_path

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario 'from /webconf/:id' do
      user = FactoryGirl.create(:user)
      room = FactoryGirl.create(:bigbluebutton_room, slug: "test", owner: user)
      visit invite_bigbluebutton_room_path(room)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(invite_bigbluebutton_room_path(room))
    end
  end

  feature "is redirected back to the page he was previously" do
    scenario 'previously in /spaces' do
      visit spaces_path
      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(spaces_path)
    end

    scenario 'previously in /spaces/:id' do
      space = FactoryGirl.create(:space, public: true)
      visit space_path(space)
      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(space_path(space))
    end

    scenario 'if the site is configured to use HTTPS' do
      # Capybara has to respond to HTTPS and the app has to be configured to use it
      Capybara.app_host = "https://#{Site.current.domain}"
      Site.current.update_attributes(ssl: true)

      user = FactoryGirl.create(:user)
      room = FactoryGirl.create(:bigbluebutton_room, slug: "test", owner: user)
      visit invite_bigbluebutton_room_path(room)

      sign_in_with @user.username, @user.password
      expect(current_path).to eq(invite_bigbluebutton_room_path(room))
    end
  end

  feature "isn't redirected back to routes he shouldn't return to" do
    scenario 'from the login page (/login)' do
      visit login_path

      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario 'after a failed login (/users/login)' do
      sign_in_with 'invalid_email', @user.password
      expect(current_path).to eq(new_user_session_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario 'from the register page (/register)' do
      visit register_path

      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario 'from the register page 2 (/users/registration/signup)' do
      visit new_user_registration_path

      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario 'after a failed registration (/users/registration)' do
      visit register_path
      click_button 'Register'
      expect(current_path).to eq("/users/registration")

      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario 'from the page to request a new password (/users/password/new)' do
      visit new_user_password_path
      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario 'when failed to request a new password (/users/password)' do
      visit new_user_password_path
      click_button "Request password"
      expect(current_path).to eq("/users/login")

      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
      has_success_message
    end

    scenario 'from the page to resend confirmation (/users/confirmation/new)' do
      visit new_user_confirmation_path
      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario 'after a failed submit in the resend confirmation form (/users/confirmation)' do
      visit new_user_confirmation_path
      click_button 'Request confirmation email'
      expect(current_path).to eq("/users/login")

      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
      has_success_message
    end

    scenario 'after changing the language' do
      visit login_path
      find("#footer-languages a", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
      has_success_message
    end

    scenario "from the page to sign in with shibboleth" do
      enable_shib
      visit shibboleth_path
      expect(current_path).to eq(shibboleth_path)

      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    skip "from the page with shibboleth info", with_js: true do
      enable_shib
      # TODO: open via xhr, it's a modal
      visit shibboleth_info_path
      expect(current_path).to eq(shibboleth_info_path)

      visit login_path

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario "after an error signing in with shibboleth" do
      enable_shib
      setup_shib @user.name, @user.email, @user.email

      visit shibboleth_path
      click_button 'Log in and link accounts'

      find("a[href='#{login_path}']", match: :first).click
      expect(current_path).to eq(login_path)

      sign_in_with @user.username, @user.password, false
      expect(current_path).to eq(my_home_path)
    end

    scenario "after the pending page" do
      Site.current.update_attributes(require_registration_approval: true)

      attrs = FactoryGirl.attributes_for(:user)
      attrs[:profile_attributes] = FactoryGirl.attributes_for(:profile)
      register_with(attrs)
      expect(current_path).to eq(my_approval_pending_path)

      User.last.approve!

      sign_in_with attrs[:email], attrs[:password]
      expect(current_path).to eq(my_home_path)
    end

    scenario 'from any xhr request' do
      skip
    end

    scenario 'from any non html request' do
      skip
    end

  end
end
