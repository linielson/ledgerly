# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Password reset", type: :request do
  let(:user) { users(:one) }
  let(:same_answer) { "Password reset instructions sent (if user with that email address exists)." }

  describe "POST /passwords" do
    it "emails reset instructions to a known address" do
      expect { post passwords_path, params: { email_address: user.email_address } }
        .to have_enqueued_mail(PasswordsMailer, :reset).with(user)

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to eq(same_answer)
    end

    it "gives the same answer for an unknown address and sends nothing" do
      expect { post passwords_path, params: { email_address: "nobody@example.com" } }
        .not_to have_enqueued_mail

      expect(response).to redirect_to(new_session_path)
      expect(flash[:notice]).to eq(same_answer)
    end

    it "allows 10 requests in 3 minutes and refuses the 11th, so the form can't flood a mailbox" do
      10.times { post passwords_path, params: { email_address: user.email_address } }

      expect { post passwords_path, params: { email_address: user.email_address } }.not_to have_enqueued_mail
      expect(flash[:alert]).to eq("Try again later.")
    end

    it "allows 10 requests per address in 3 minutes, even from different IPs" do
      10.times do |i|
        post passwords_path, params: { email_address: user.email_address }, env: { "REMOTE_ADDR" => "10.0.0.#{i}" }
      end

      expect { post passwords_path, params: { email_address: " ONE@example.com" }, env: { "REMOTE_ADDR" => "10.0.0.99" } }
        .not_to have_enqueued_mail
      expect(flash[:alert]).to eq("Try again later.")
    end
  end

  describe "GET /passwords/:token/edit" do
    it "shows the new password form for a valid token" do
      get edit_password_path(user.password_reset_token)

      expect(response).to have_http_status(:ok)
    end

    it "refuses a forged token" do
      get edit_password_path("forged")

      expect(response).to redirect_to(new_password_path)
      expect(flash[:alert]).to eq("Password reset link is invalid or has expired.")
    end

    it "refuses a token older than 15 minutes" do
      token = user.password_reset_token

      travel 15.minutes + 1.second do
        get edit_password_path(token)

        expect(response).to redirect_to(new_password_path)
      end
    end
  end

  describe "PATCH /passwords/:token" do
    let(:new_password) { { password: "a new long password", password_confirmation: "a new long password" } }

    it "sets the new password" do
      patch password_path(user.password_reset_token), params: new_password

      expect(response).to redirect_to(new_session_path)
      expect(user.reload.authenticate("a new long password")).to eq(user)
    end

    it "signs the user out everywhere, so a stolen session dies with the old password" do
      sign_in_as(user)
      user.sessions.create! # another device

      expect { patch password_path(user.password_reset_token), params: new_password }
        .to change { user.sessions.count }.from(2).to(0)
    end

    it "refuses to use the same link twice" do
      token = user.password_reset_token
      patch password_path(token), params: new_password

      patch password_path(token), params: { password: "another one", password_confirmation: "another one" }

      expect(response).to redirect_to(new_password_path)
      expect(user.reload.authenticate("a new long password")).to eq(user)
    end

    it "keeps the old password when the confirmation doesn't match" do
      token = user.password_reset_token
      patch password_path(token), params: { password: "a new long password", password_confirmation: "different" }

      expect(response).to redirect_to(edit_password_path(token))
      expect(flash[:alert]).to eq("Password confirmation doesn't match Password")
      expect(user.reload.authenticate("password")).to eq(user)
    end

    it "says why when the new password is refused for another reason" do
      token = user.password_reset_token
      too_long = "é" * 37 # 37 characters fit the form's maxlength of 72, but they are 74 bytes

      patch password_path(token), params: { password: too_long, password_confirmation: too_long }

      expect(response).to redirect_to(edit_password_path(token))
      expect(flash[:alert]).to eq("Password is too long")
    end
  end

  it "doesn't route the password actions that don't exist" do
    get "/passwords"
    expect(response).to have_http_status(:not_found)
  end
end
