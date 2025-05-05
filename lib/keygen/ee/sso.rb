# frozen_string_literal: true

require 'workos'

module Keygen
  module EE
    module SSO
      State = Data.define(:email, :environment_id)

      extend self

      def redirect_url(account:, environment:, callback_url:, email: nil)
        WorkOS::SSO.authorization_url(
          client_id: WORKOS_CLIENT_ID,
          organization: account.sso_organization_id,
          redirect_uri: callback_url,
          domain_hint: account.sso_organization_domains.first,
          login_hint: email,
          state: encrypt_state(
            { email:, environment_id: environment&.id, }, # email acts as a salt
            secret_key: account.secret_key,
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
        raise Keygen::Error::InvalidSingleSignOnError.new(e.message, code: "SSO_#{e.error.upcase}")
      end

      def encrypt_state(state, secret_key:)
        crypt = ActiveSupport::MessageEncryptor.new(derive_key(secret_key), serializer: JSON)
        enc   = crypt.encrypt_and_sign(state)
                     .split('--')
                     .map { strict64_to_urlsafe64(_1) }
                     .join('.')

        enc
      end

      def decrypt_state(ciphertext, secret_key:)
        return nil if ciphertext.blank?

        crypt = ActiveSupport::MessageEncryptor.new(derive_key(secret_key), serializer: JSON)
        enc   = ciphertext.split('.')
                          .map { urlsafe64_to_strict64(_1) }
                          .join('--')

        dec = crypt.decrypt_and_verify(enc)

        State.new(**dec.symbolize_keys)
      rescue ActiveSupport::MessageEncryptor::InvalidMessage
        nil
      end

      private

      def strict64_to_urlsafe64(enc)
        Base64.urlsafe_encode64(Base64.strict_decode64(enc), padding: false)
      rescue ArgumentError
        nil
      end

      def urlsafe64_to_strict64(enc)
        Base64.strict_encode64(Base64.urlsafe_decode64(enc))
      rescue ArgumentError
        nil
      end

      def derive_key(secret_key)
        keygen = ActiveSupport::KeyGenerator.new(secret_key)
        salt   = 'sso'.freeze

        keygen.generate_key(salt, 32)
      end
    end
  end
end
