class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_user_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { too_many_requests }
  rate_limit(
    to: 10, within: 3.minutes, only: :create, name: "per-address",
    by: -> { params[:email_address].to_s.strip.downcase }, with: -> { too_many_requests }
  )

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(user).deliver_later
    end

    redirect_to new_session_path, notice: "Password reset instructions sent (if user with that email address exists)."
  end

  def edit
  end

  def update
    if reset_password_and_sign_out_everywhere
      redirect_to new_session_path, notice: "Password has been reset."
    else
      redirect_to edit_password_path(params[:token]), alert: @user.errors.full_messages.to_sentence
    end
  end

  private

    def set_user_by_token
      @user = User.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to new_password_path, alert: "Password reset link is invalid or has expired."
    end

    def reset_password_and_sign_out_everywhere
      User.transaction do
        @user.update(params.permit(:password, :password_confirmation)) && @user.sessions.destroy_all
      end
    end

    def too_many_requests
      redirect_to new_password_path, alert: "Try again later."
    end
end
