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
        Keygen.logger.warn { "[sso] failed to find account: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect}" }

        raise Keygen::Error::InvalidSingleSignOnError.new('failed to find account', code: 'SSO_INVALID_ACCOUNT')
      end

      # verify the user's email domain matches one of the account's domains
      unless account.sso_for?(profile.email)
        Keygen.logger.warn { "[sso] email is not allowed: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect} account_id=#{account.id.inspect}" }

        raise Keygen::Error::InvalidSingleSignOnError.new('email is not allowed', code: 'SSO_INVALID_DOMAIN')
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
            Keygen.logger.warn { "[sso] user is not allowed: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect} account_id=#{account.id.inspect}" }

            raise Keygen::Error::InvalidSingleSignOnError.new('user is not allowed', code: 'SSO_INVALID_USER')
          end

          u.sso_profile_id    = profile.id
          u.sso_connection_id = profile.connection_id
          u.sso_idp_id        = profile.idp_id
          u.first_name        = profile.first_name
          u.last_name         = profile.last_name
          u.email             = profile.email

          # TODO(ezekg) eventually implement workos groups/roles? https://workos.com/docs/sso/identity-provider-role-assignment
          u.grant_role! :admin
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
        Keygen.logger.warn { "[sso] failed to update user: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect} account_id=#{account.id.inspect} user_id=#{user.id.inspect} error_messages=#{user.errors.messages.inspect}" }

        raise Keygen::Error::InvalidSingleSignOnError.new('failed to update user', code: 'SSO_INVALID_USER')
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
        Keygen.logger.warn { "[sso] failed to generate session: profile_id=#{profile.id.inspect} organization_id=#{profile.organization_id.inspect} account_id=#{account.id.inspect} user_id=#{user.id.inspect} session_id=#{session.id.inspect} error_messages=#{session.errors.messages.inspect}" }

        raise Keygen::Error::InvalidSingleSignOnError.new('failed to generate session', code: 'SSO_INVALID_SESSION')
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
