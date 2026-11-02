# frozen_string_literal: true

require "rails_helper"

# WebSocket connections skip controllers, so this is their require_authentication: the same signed session cookie.
RSpec.describe ApplicationCable::Connection, type: :channel do
  it "connects as the signed-in user" do
    session = users(:one).sessions.create!
    cookies.signed[:session_id] = session.id

    connect "/cable"

    expect(connection.current_user).to eq(users(:one))
  end

  it "rejects a connection without a session cookie" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "rejects a cookie for a session that no longer exists" do
    cookies.signed[:session_id] = 0

    expect { connect "/cable" }.to have_rejected_connection
  end
end
