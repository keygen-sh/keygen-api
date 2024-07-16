# frozen_string_literal: true

module Auth
  KEYGEN_PORTAL_HOST = ENV.fetch('KEYGEN_PORTAL_HOST') { 'portal.keygen.sh' }

  class SsoController < Api::V1::BaseController
    include ActionController::Cookies

    skip_verify_authorized

    typed_query {
      param :state, type: :string, optional: true, allow_blank: true
      param :code, type: :string
    }
    def callback
      code, state = sso_query.values_at(:code, :state)
      profile     = WorkOS::SSO.profile_and_token(client_id: WORKOS_CLIENT_ID, code:)
                               .profile

      # TODO(ezekg) error handling e.g. code is invalid, error callback,
      #             failure to find/create user, etc.

      account = Account.where.not(sso_organization_id: nil) # sanity-check
                       .find_by!(
                         sso_organization_id: profile.organization_id,
                       )

      # WorkOS recommends JIT-user-provisioning: https://workos.com/docs/sso/jit-provisioning
      #
      # 1. First, we attempt to find the user by their profile ID.
      # 2. Next, we attempt to find the user by their email.
      # 3. Otherwise, create a new user.
      #
      # Afterwards, we keep the user's profile up-to-date.
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

      user.update!(
        # Generate a nonce to assert that only 1 SSO-based session can be
        # active for a user at any given time.
        session_nonce: SecureRandom.random_number(2**32),
        # Keep the user's profile up-to-date with the IdP.
        first_name: profile.first_name,
        last_name: profile.last_name,
        email: profile.email,
      )

      # We use encrypted session cookies for SSO authentication because we
      # don't want to expose a token in the redirect URL, and we don't
      # want the token used for an API integration.
      session[:nonce]      = user.session_nonce
      session[:account_id] = account.id
      session[:user_id]    = user.id

      redirect_to portal_url(account), status: :temporary_redirect,
                                       allow_other_host: true
    end
  end
end
