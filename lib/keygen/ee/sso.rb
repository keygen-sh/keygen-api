# frozen_string_literal: true

require 'workos'

module Keygen
  module EE
    module SSO
      State = Data.define(:email, :environment_id)

      extend self

      def redirect_url(account:, callback_url:, environment: nil, email: nil, expires_in: 5.minutes)
        WorkOS::SSO.authorization_url(
          client_id: WORKOS_CLIENT_ID,
          organization: account.sso_organization_id,
          redirect_uri: callback_url,
          domain_hint: account.sso_organization_domains.first,
          login_hint: email,
          state: encrypt_state(
            { email:, environment_id: environment&.id }, # email acts as a salt
            secret_key: account.secret_key,
            expires_in:,
          ),
        )
      end

      # redeem an authentication code for a user profile
      def redeem_code(code:)
        res = WorkOS::SSO.profile_and_token(
          client_id: WORKOS_CLIENT_ID,
          code:,
        )

        res.profile
      rescue WorkOS::APIError => e
        raise Keygen::Error::InvalidSingleSignOnError.new("bad code: #{e.message}", code: "SSO_#{e.error.upcase}")
      end

      def decrypt_state(ciphertext, secret_key:)
        return nil if ciphertext.blank?

        crypt = ActiveSupport::MessageEncryptor.new(derive_key(secret_key), serializer: JSON)
        enc   = ciphertext.split('.')
                          .map { urlsafe64_to_strict64(it) }
                          .join('--')

        dec = crypt.decrypt_and_verify(enc)
        raise ActiveSupport::MessageEncryptor::InvalidMessage, 'invalid message' if dec.blank?

        State.new(**dec.symbolize_keys)
      rescue ActiveSupport::MessageEncryptor::InvalidMessage => e
        raise Keygen::Error::InvalidSingleSignOnError.new("bad state: #{e.message}", code: 'SSO_STATE_INVALID')
      end

      private

      def encrypt_state(state, secret_key:, expires_in: nil)
        crypt = ActiveSupport::MessageEncryptor.new(derive_key(secret_key), serializer: JSON)
        enc   = crypt.encrypt_and_sign(state, expires_in:)
                     .split('--')
                     .map { strict64_to_urlsafe64(it) }
                     .join('.')

        enc
      end

      def strict64_to_urlsafe64(enc)
        Base64.urlsafe_encode64(Base64.strict_decode64(enc), padding: false)
      rescue ArgumentError => e
        raise ActiveSupport::MessageEncryptor::InvalidMessage, "bad encoding: #{e.message}"
      end

      def urlsafe64_to_strict64(enc)
        Base64.strict_encode64(Base64.urlsafe_decode64(enc))
      rescue ArgumentError => e
        raise ActiveSupport::MessageEncryptor::InvalidMessage, "bad encoding: #{e.message}"
      end

      def derive_key(secret_key)
        keygen = ActiveSupport::KeyGenerator.new(secret_key)
        salt   = 'sso'.freeze

        keygen.generate_key(salt, 32)
      end
    end
  end
end
