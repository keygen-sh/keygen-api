# frozen_string_literal: true

module Keygen
  module SSO
    class << self
      def authorization_url(account:, email:, provider: nil)
        state = { email: } # used to assert redeemer matches requestor

        WorkOS::SSO.authorization_url(
          client_id: WORKOS_CLIENT_ID,
          organization: account.sso_organization_id,
          state: encrypt(state, secret_key: account.secret_key),
          redirect_uri:,
          provider:,
        )
      end

      # Redeem an authentication code for a user profile.
      def redeem_code(code:)
        WorkOS::SSO.profile_and_token(client_id: WORKOS_CLIENT_ID, code:)
                   .profile
      rescue WorkOS::APIError => e
        raise Keygen::Error::InvalidSingleSignOnError.new(e.message)
      end

      # Lookup the account for a user profile.
      def lookup_account(profile:)
        Account.where.not(sso_organization_id: nil) # sanity-check
                     .find_by!(
                       sso_organization_id: profile.organization_id,
                     )
      rescue ActiveRecord::RecordNotFound
        raise Keygen::Error::InvalidSingleSignOnError.new('account is invalid')
      end

      # WorkOS recommends JIT-user-provisioning: https://workos.com/docs/sso/jit-provisioning
      #
      # 1. First, we attempt to lookup the user by their profile ID.
      # 2. Next, we attempt to lookup the user by their email.
      # 3. Otherwise, initialize a new user.
      #
      # Lastly, we keep the user's attributes up-to-date.
      def lookup_or_provision_user(profile:, account:, save: false, validate: false)
        user = account.users.then do |users|
          users.find_by(sso_profile_id: profile.id) || users.find_or_initialize_by(email: profile.email) do |u|
            u.sso_profile_id    = profile.id
            u.sso_connection_id = profile.connection_id
            u.sso_idp_id        = profile.idp_id
            u.first_name        = profile.first_name
            u.last_name         = profile.last_name
            u.email             = profile.email

            # TODO(ezekg) eventually implement workos groups?
            u.grant_role! :admin
          end
        end

        # keep the user's attributes up-to-date with the IdP
        user.assign_attributes(
          sso_profile_id: profile.id,
          sso_connection_id: profile.connection_id,
          sso_idp_id: profile.idp_id,
          first_name: profile.first_name,
          last_name: profile.last_name,
          email: profile.email,
        )

        user.save!(validate:) if save

        user
      end

      def raise_on_request_error!(request)
        if (code, message = request.query_parameters.values_at(:error, :error_description)).any?
          raise Keygen::Error::InvalidSingleSignOnError.new(message, code: "SSO_#{code.upcase}")
        end
      end

      def raise_on_state_error!(state, account:, profile:)
        unless state.blank?
          value = decrypt(state, secret_key: account.secret_key).with_indifferent_access

          # assert the profile's email matches the email that initiated the authn
          unless profile.email == value[:email]
            raise Keygen::Error::InvalidSingleSignOnError.new('email is invalid')
          end
        end
      end

      private

      def redirect_uri = Rails.application.routes.url_helpers.sso_callback_url

      def encrypt(plaintext, secret_key:)
        crypt = ActiveSupport::MessageEncryptor.new(derive_key(secret_key), serializer: JSON)
        enc   = crypt.encrypt_and_sign(plaintext)
                     .split('--')
                     .map { |s| Base64.urlsafe_encode64(Base64.strict_decode64(s), padding: false) }
                     .join('.')

        enc
      end

      def decrypt(ciphertext, secret_key:)
        crypt = ActiveSupport::MessageEncryptor.new(derive_key(secret_key), serializer: JSON)
        enc   = ciphertext.split('.')
                          .map { |s| Base64.strict_encode64(Base64.urlsafe_decode64(s)) }
                          .join('--')

        crypt.decrypt_and_verify(enc)
      end

      def derive_key(secret_key)
        keygen = ActiveSupport::KeyGenerator.new(secret_key)
        salt   = 'sso'.freeze

        keygen.generate_key(salt, 32)
      end
    end
  end
end
