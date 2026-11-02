class PurgeExpiredSessionsJob < ApplicationJob
  def perform
    Session.expired.delete_all
  end
end
