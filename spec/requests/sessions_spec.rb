# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:user) { users(:one) }

  describe "GET /session/new" do
    it "shows the sign-in form" do
      get new_session_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Sign in")
    end
  end

  describe "POST /session" do
    it "signs in and goes to the home page" do
      sign_in_as(user)

      expect(response).to redirect_to(root_url)
    end

    it "records the browser and IP of the new session" do
      credentials = { email_address: user.email_address, password: "password" }

      expect { post session_path, params: credentials, headers: { "User-Agent" => "Firefox/140.0" } }
        .to change(user.sessions, :count).by(1)

      expect(user.sessions.last).to have_attributes(ip_address: "127.0.0.1", user_agent: "Firefox/140.0")
    end

    it "accepts the email with other casing and surrounding spaces" do
      post session_path, params: { email_address: "  ONE@Example.com ", password: "password" }

      expect(response).to redirect_to(root_url)
    end

    it "goes back to the page that asked for sign-in" do
      get root_path(tab: "invoices")
      sign_in_as(user)

      expect(response).to redirect_to(root_url(tab: "invoices"))
    end

    context "when the credentials are wrong" do
      it "refuses a wrong password with a message that doesn't say which part was wrong" do
        expect { sign_in_as(user, password: "wrong") }.not_to change(Session, :count)
        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end

      it "gives the same answer for an unknown email, so it doesn't reveal who has an account" do
        post session_path, params: { email_address: "nobody@example.com", password: "password" }

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("Try another email address or password.")
      end
    end

    context "when sign-in is attempted too often" do
      it "allows 10 attempts in 3 minutes and refuses the 11th" do
        10.times { sign_in_as(user, password: "wrong") }
        expect(flash[:alert]).to eq("Try another email address or password.")

        sign_in_as(user)

        expect(response).to redirect_to(new_session_path)
        expect(flash[:alert]).to eq("Try again later.")
      end

      it "allows attempts again after 3 minutes" do
        11.times { sign_in_as(user, password: "wrong") }

        travel 3.minutes + 1.second do
          sign_in_as(user)

          expect(response).to redirect_to(root_url)
        end
      end
    end
  end

  describe "DELETE /session" do
    it "signs out, forgets the session and asks for sign-in again" do
      sign_in_as(user)

      expect { delete session_path }.to change(Session, :count).by(-1)
      expect(response).to redirect_to(new_session_path)

      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end

  # resource :session only routes the actions that exist (docs/conventions.md: no unused generated code).
  it "doesn't route the session actions that don't exist" do
    sign_in_as(user)

    get "/session"
    expect(response).to have_http_status(:not_found)

    get "/session/edit"
    expect(response).to have_http_status(:not_found)
  end
end
