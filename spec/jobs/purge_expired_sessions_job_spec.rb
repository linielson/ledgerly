# frozen_string_literal: true

require "rails_helper"

# Runs daily (config/recurring.yml), so sessions that are never used again don't pile up.
RSpec.describe "PurgeExpiredSessionsJob", type: :job do
  let(:user) { users(:one) }

  it "deletes sessions unused for more than 14 days and sessions older than 30 days, and keeps the rest" do
    idle = travel_to(15.days.ago) { user.sessions.create! }
    old = travel_to(31.days.ago) { user.sessions.create! }.tap { |session| session.touch }
    fresh = user.sessions.create!

    PurgeExpiredSessionsJob.perform_now

    expect(Session.where(id: [ idle, old, fresh ])).to contain_exactly(fresh)
  end
end
