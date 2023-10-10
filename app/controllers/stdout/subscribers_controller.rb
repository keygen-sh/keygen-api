# frozen_string_literal: true

module Stdout
  class SubscribersController < ApplicationController
    skip_verify_authorized

    def unsubscribe
      ciphertext = params.fetch(:ciphertext)
      email      = decrypt(ciphertext)
      return if
        email.nil?

      user = User.where(email: email, stdout_unsubscribed_at: nil)

      # Unsubscribe all users with this email across all accounts
      user.update_all(stdout_unsubscribed_at: Time.current)
    rescue => e
      Keygen.logger.error "[stdout] Unsubscribe failed: err=#{e.message}"
    ensure
      response.headers['Content-Type'] = 'text/plain'

      render plain: "You've been unsubscribed"
    end

    private

    def secret_key = ENV.fetch('STDOUT_SECRET_KEY')

    def decrypt(ciphertext)
      crypt = ActiveSupport::MessageEncryptor.new(secret_key, serializer: JSON)
      enc   = ciphertext.split('.')
                        .map { |s| Base64.strict_encode64(Base64.urlsafe_decode64(s)) }
                        .join('--')

      crypt.decrypt_and_verify(enc)
    rescue => e
      Keygen.logger.warn "[stdout.decrypt] Decrypt failed: err=#{e.message}"

      nil
    end
  end
end
