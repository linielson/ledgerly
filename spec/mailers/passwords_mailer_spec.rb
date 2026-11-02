# frozen_string_literal: true

require "rails_helper"

RSpec.describe PasswordsMailer, type: :mailer do
  let(:user) { users(:one) }
  let(:mail) { described_class.reset(user) }

  it "goes to the user, from Ledgerly" do
    expect(mail.to).to eq([ "one@example.com" ])
    expect(mail[:from].to_s).to eq("Ledgerly <no-reply@linirosa.com>")
    expect(mail.subject).to eq("Reset your password")
  end

  it "links to the reset form with a token that finds the user" do
    token = mail.text_part.body.to_s[%r{/passwords/([^/]+)/edit}, 1]

    expect(User.find_by_password_reset_token(token)).to eq(user)
  end
end
