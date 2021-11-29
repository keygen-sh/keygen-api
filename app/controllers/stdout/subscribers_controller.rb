# frozen_string_literal: true

module Stdout
  class SubscribersController < ApplicationController
    def unsubscribe
      skip_authorization

      ciphertext = params.fetch(:ciphertext)
      email      = decrypt(ciphertext)
      return if
        email.nil?

      user = User.where(email: email, stdout_unsubscribed_at: nil)

      # Unsubscribe all users with this email across all accounts
      user.update_all(stdout_unsubscribed_at: Time.current)
    rescue => e
      Keygen.logger.warn "[stdout] Unsubscribe failed: err=#{e.message}"
    ensure
      render plain: "You've been unsubscribed"
    end

    private

    def decrypt(ciphertext)
      crypt = ActiveSupport::MessageEncryptor.new(secret_key, serializer: JSON)
      dec   = crypt.decrypt_and_verify(ciphertext.gsub('.', '--'))

      dec
    rescue => e
      Keygen.logger.warn "[stdout.decrypt] Decrypt failed: err=#{e.message}"

      nil
    end

    def secret_key
      Rails.application.secrets.secret_key_stdout
    end
  end
end
