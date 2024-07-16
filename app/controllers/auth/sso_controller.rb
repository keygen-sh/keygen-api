# frozen_string_literal: true

module Auth
  KEYGEN_PORTAL_HOST = ENV.fetch('KEYGEN_PORTAL_HOST') { 'portal.keygen.sh' }

  class SsoController < Api::V1::BaseController
    include ActionController::Cookies

    skip_verify_authorized

    def callback
      Keygen::SSO.raise_on_request_error!(request) # handle errors

      code, state = request.query_parameters.values_at(:code, :state)
      profile     = Keygen::SSO.redeem_code(code:)
      account     = Keygen::SSO.lookup_account(
        profile:,
      )

      # assert the authn state matches what we expect e.g. the original email
      # equals actual authenticated email
      Keygen::SSO.raise_on_state_error!(state,
        profile:,
        account:,
      )

      user = Keygen::SSO.lookup_or_provision_user(profile:, account:)
      user.update!(
        # Generate a nonce to assert that only 1 SSO-based session can be
        # active for a user at any given time.
        session_nonce: SecureRandom.random_number(2**32),
      )

      # We use encrypted session cookies for SSO authentication because we
      # don't want to expose a token in the redirect URL, and we don't
      # want the token used for an API integration.
      session[:nonce]      = user.session_nonce
      session[:account_id] = account.id
      session[:user_id]    = user.id

      redirect_to portal_url(account), status: :see_other, allow_other_host: true
    end
  end
end
