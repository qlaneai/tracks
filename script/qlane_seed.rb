# Seeds the logins for qlane's test target (docker-compose.qlane.yml, ai.qlane.postdeploy).
# Run with: bin/rails runner script/qlane_seed.rb
#
# Idempotent: each run converges both users to the state below, so a second run changes nothing.
# The passwords come from QA_PASSWORD and ADMIN_PASSWORD, which docker-compose.qlane.yml passes to
# the web service from the test target's variables. Never commit their values.
#
# Order matters. The admin is created first so that the QA login is never the first user:
# UsersController#new and #create let anyone sign up while User.no_users_yet? holds, and an admin
# can always reach /signup. The QA baseline logs in as the non-admin `qatester`, which with
# open_signups: false sees the "no signups" page at /signup. User validates a login of 3 to 80
# characters, which is why the QA login is not the shorter `qa`.

def ensure_user(login:, password:, admin:)
  user = User.find_by(login: login)
  if user.nil?
    user = User.new(login: login, password: password, password_confirmation: password)
    user.is_admin = admin
    user.save!
    action = "created"
  else
    action = "unchanged"
    unless user.password_matches?(password)
      user.change_password(password, password)
      action = "updated"
    end
    if user.is_admin != admin
      user.update!(is_admin: admin)
      action = "updated"
    end
  end
  # UsersController#create gives every new user a preference row; the app reads prefs on
  # every logged-in page.
  if user.preference.nil?
    user.create_preference!(locale: I18n.locale)
    action = "updated" if action == "unchanged"
  end
  puts "qlane seed: #{login} (is_admin=#{user.is_admin}) #{action}"
end

def required_env(name)
  value = ENV[name].to_s
  abort "qlane seed: #{name} is not set; set it on the test target" if value.empty?
  value
end

ensure_user(login: "admin", password: required_env("ADMIN_PASSWORD"), admin: true)
ensure_user(login: "qatester", password: required_env("QA_PASSWORD"), admin: false)
