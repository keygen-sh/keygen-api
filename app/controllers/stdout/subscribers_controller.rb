# frozen_string_literal: true

module Stdout
  class SubscribersController < ApplicationController
    include Rendering::HTML

    skip_verify_authorized

    def unsubscribe
      ciphertext = params.fetch(:ciphertext)
      email      = decrypt(ciphertext)
      return if
        email.nil?

      user = User.where(email:, stdout_unsubscribed_at: nil)

      # Unsubscribe all users with this email across all accounts
      user.update_all(stdout_unsubscribed_at: Time.current)
    rescue => e
      Keygen.logger.error "[stdout] Unsubscribe failed: err=#{e.message}"
    ensure
      render html: <<~HTML.html_safe
        You've been unsubscribed. To resubscribe, follow this link: #{helpers.link_to(nil, stdout_resubscribe_url(ciphertext))}
      HTML
    end

    def resubscribe
      ciphertext = params.fetch(:ciphertext)
      email      = decrypt(ciphertext)
      return if
        email.nil?

      user = User.where.not(stdout_unsubscribed_at: nil)
                 .where(email:)

      # Resubscribe all users with this email across all accounts
      user.update_all(stdout_unsubscribed_at: nil)
    rescue => e
      Keygen.logger.error "[stdout] Resubscribe failed: err=#{e.message}"
    ensure
      render html: <<~HTML.html_safe
        You've been resubscribed. To unsubscribe, follow this link: #{helpers.link_to(nil, stdout_unsubscribe_url(ciphertext))}
      HTML
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
