# frozen_string_literal: true

module Auth
  class SsoController < Api::V1::BaseController
    DEFAULT_SESSION_DURATION = 8.hours

    before_action :require_ee!
    before_action :handle_callback_error,
      only: %i[callback]

    skip_verify_authorized

    def callback
      code = request.query_parameters[:code]

      # redeem the callback authentication code for a user profile
      profile = Keygen::EE::SSO.redeem_code(code:)

      # lookup the account for the user's org
      account = Account.where.not(sso_organization_id: nil) # sanity-check
                             .find_by(
                               sso_organization_id: profile.organization_id,
                             )

      unless account.present?
        Keygen.logger.warn { "[sso] account was not found: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect}" }

        raise Keygen::Error::InvalidSingleSignOnError.new('account was not found', code: 'SSO_ACCOUNT_NOT_FOUND')
      end

      # verify that either the user's email domain matches one of the account's domains
      # or that the account allows external authn e.g. for third-party admins
      unless account.sso_for?(profile.email) || account.sso_external_authn?
        Keygen.logger.warn { "[sso] user is not allowed: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect} account_id=#{account.id.inspect}" }

        raise Keygen::Error::InvalidSingleSignOnError.new('user is not allowed', code: 'SSO_USER_NOT_ALLOWED')
      end

      # workos recommends jit-provisioning: https://workos.com/docs/sso/jit-provisioning
      #
      # 1. first, we attempt to lookup the user by their workos profile.
      # 2. next, we attempt to lookup the user by their email.
      # 3. otherwise, initialize a new user.
      #
      # lastly, we keep the user's attributes up-to-date.
      user = account.users.then do |users|
        users.find_by(sso_profile_id: profile.id) || users.find_or_initialize_by(email: profile.email) do |u|
          unless account.sso_jit_provisioning?
            Keygen.logger.warn { "[sso] user was not found: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect} account_id=#{account.id.inspect}" }

            raise Keygen::Error::InvalidSingleSignOnError.new('user was not found', code: 'SSO_USER_NOT_FOUND')
          end

          u.sso_profile_id    = profile.id
          u.sso_connection_id = profile.connection_id
          u.sso_idp_id        = profile.idp_id
          u.first_name        = profile.first_name
          u.last_name         = profile.last_name
          u.email             = profile.email

          # TODO(ezekg) eventually implement workos groups/roles? https://workos.com/docs/sso/identity-provider-role-assignment
          u.grant_role! :read_only
        end
      end

      # keep the user's attributes up-to-date with the IdP
      user.update(
        sso_profile_id: profile.id,
        sso_connection_id: profile.connection_id,
        sso_idp_id: profile.idp_id,
        first_name: profile.first_name,
        last_name: profile.last_name,
        email: profile.email,
      )

      unless user.errors.empty?
        Keygen.logger.warn { "[sso] user is not valid: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect} account_id=#{account.id.inspect} user_id=#{user.id.inspect} error_messages=#{user.errors.messages.inspect}" }

        raise Keygen::Error::InvalidSingleSignOnError.new('user is not valid', code: 'SSO_USER_INVALID')
      end

      session = user.transaction do
        # FIXME(ezekg) quirk: https://stackoverflow.com/a/78727914/3247081
        user.sessions.delete_all(:delete_all) # clear current sessions
        user.sessions.create(
          expiry: (account.sso_session_duration.presence || DEFAULT_SESSION_DURATION).seconds.from_now,
          user_agent: request.user_agent,
          ip: request.remote_ip,
        )
      end

      unless session.errors.empty?
        Keygen.logger.warn { "[sso] session is not valid: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect} account_id=#{account.id.inspect} user_id=#{user.id.inspect} session_id=#{session.id.inspect} error_messages=#{session.errors.messages.inspect}" }

        raise Keygen::Error::InvalidSingleSignOnError.new('session is not valid', code: 'SSO_SESSION_INVALID')
      end

      set_session_id_cookie(session,
        skip_verify_origin: true, # i.e. allow cookie to be set from outside Portal origin
      )

      redirect_to portal_url(account), status: :see_other, allow_other_host: true
    end

    private

    def require_ee! = super(entitlements: %i[sso])
    def handle_callback_error
      return unless request.query_parameters.key?(:error)

      message, code = request.query_parameters.values_at(
        :error_description,
        :error,
      )

      raise Keygen::Error::InvalidSingleSignOnError.new(message,
        code: "SSO_#{code.upcase}",
      )
    end
  end
end
