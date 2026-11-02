class Session < ApplicationRecord
  belongs_to :user

  IDLE_TIMEOUT = 14.days
  MAX_AGE = 30.days

  scope :expired, -> { where(updated_at: ...IDLE_TIMEOUT.ago).or(where(created_at: ...MAX_AGE.ago)) }

  def expired?
    updated_at < IDLE_TIMEOUT.ago || created_at < MAX_AGE.ago
  end
end
