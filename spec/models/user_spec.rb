# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  it "stores the email stripped and downcased" do
    user = User.create!(email_address: "  New.Person@Example.COM ", password: "password")

    expect(user.email_address).to eq("new.person@example.com")
  end

  it "finds a user by email with any casing" do
    expect(User.find_by(email_address: "ONE@EXAMPLE.COM")).to eq(users(:one))
  end

  # The unique index enforces this even when two sign-ups race past model validations.
  it "can't share an email with another user, whatever the casing" do
    expect { User.create!(email_address: "One@Example.com", password: "password") }
      .to raise_error(ActiveRecord::RecordNotUnique)
  end

  it "keeps only a bcrypt digest of the password" do
    user = User.create!(email_address: "digest@example.com", password: "password")

    expect(user.password_digest).to start_with("$2a$")
    expect(user.password_digest).not_to include("password")
  end
end
