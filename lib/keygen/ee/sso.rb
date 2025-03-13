# frozen_string_literal: true

require 'workos'

module Keygen
  module EE
    module SSO
      extend self

      def redirect_url(account:, callback_url:, email: nil)
        WorkOS::SSO.authorization_url(
          client_id: WORKOS_CLIENT_ID,
          organization: account.sso_organization_id,
          redirect_uri: callback_url,
          domain_hint: account.sso_organization_domains.first,
          login_hint: email,
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
    end
  end
end
