module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      set_current_user || reject_unauthorized_connection
    end

    private

      def set_current_user
        user_session = Session.find_by(id: cookies.signed[:session_id])
        return unless user_session
        return if user_session.expired?

        self.current_user = user_session.user
      end
  end
end
