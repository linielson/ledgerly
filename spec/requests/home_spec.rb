# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Home", type: :request do
  it "asks for sign-in first" do
    get root_path

    expect(response).to redirect_to(new_session_path)
  end

  it "shows the signed-in user's email and a way to sign out" do
    sign_in_as(users(:one))
    get root_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("one@example.com")
    expect(response.body).to include("Sign out")
  end
end
