# frozen_string_literal: true

module Stdout
  class SubscribersController
    def unsubscribe
      enc  = params.fetch(:email)
      dec  = Base64.urlsafe_decode64(enc)
      user = User.where(email: dec)

      # Unsubscribe all users with this email across all accounts
      user.update!(stdout_unsubscribed_at: Time.current)
    rescue => e
      Keygen.logger.warn "[stdout] Unsubscribe failed: err=#{e.message}"
    ensure
      render plain: "You've been unsubscribed"
    end
  end
end
