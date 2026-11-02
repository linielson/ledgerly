# frozen_string_literal: true

require "rails_helper"

# Sessions expire after 14 days without activity, and 30 days after sign-in even when in use (docs/authentication.md).
RSpec.describe "Session expiry", type: :request do
  let(:user) { users(:one) }

  before { sign_in_as(user) }

  it "keeps the session while it is used within 14 days" do
    travel 13.days
    get root_path
    expect(response).to have_http_status(:ok)

    travel 13.days
    get root_path
    expect(response).to have_http_status(:ok)
  end

  it "signs out after 14 days without activity" do
    travel 14.days + 1.minute
    get root_path

    expect(response).to redirect_to(new_session_path)
  end

  it "signs out 30 days after sign-in, even when used every day" do
    3.times do
      travel 10.days - 1.minute
      get root_path
      expect(response).to have_http_status(:ok)
    end

    travel 1.day
    get root_path

    expect(response).to redirect_to(new_session_path)
  end

  it "deletes an expired session instead of keeping it around" do
    travel 15.days

    expect { get root_path }.to change(Session, :count).by(-1)
  end
end
