# frozen_string_literal: true

# Signs in through the real form, so request specs exercise the same path a browser does. Fixture users have the
# password "password" (spec/fixtures/users.yml).
module AuthenticationHelpers
  def sign_in_as(user, password: "password")
    post session_path, params: { email_address: user.email_address, password: password }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
end
