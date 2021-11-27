# frozen_string_literal: true

module Stdout
  class SubscribersController < ApplicationController
    def unsubscribe
      skip_authorization

      enc  = params.fetch(:enc)
      dec  = decrypt(enc)
      user = User.where(email: dec)

      # Unsubscribe all users with this email across all accounts
      user.update!(stdout_unsubscribed_at: Time.current)
    rescue => e
      Keygen.logger.warn "[stdout] Unsubscribe failed: err=#{e.message}"
    ensure
      render plain: "You've been unsubscribed"
    end

    private

    def decrypt
    end
  end
end
