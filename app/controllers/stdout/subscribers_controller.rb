# frozen_string_literal: true

module Stdout
  class SubscribersController
    def unsubscribe
      enc  = params.fetch(:email)
      dec  = Base64.urlsafe_decode64(enc)
      user = User.where(email: dec)

      # Unsubscribe all users with this email across all accounts
      user.update!(unsubscribed_from_stdout_at: Time.current)
    rescue => e
      Keygen.logger.warn "[stdout] Unsubscribe failed: id=#{params[:id]} err=#{e.message}"
    ensure
      render plain: "You've been unsubscribed"
    end
  end
end
