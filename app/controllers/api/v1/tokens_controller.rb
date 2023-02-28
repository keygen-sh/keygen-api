# frozen_string_literal: true

module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    has_scope(:environment, allow_blank: true) { |c, s, v| s.for_environment(v.presence, strict: true) }
    has_scope(:bearer, type: :hash, using: %i[type id]) { |c, s, (t, id)| s.for_bearer(t, id) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!, only: %i[index regenerate regenerate_current]
    before_action :authenticate_with_token!, except: %i[generate]
    before_action :set_token, only: %i[show regenerate revoke]

    def index
      tokens = apply_pagination(authorized_scope(apply_scopes(current_account.tokens)).preload(bearer: %i[role]))
      authorize! tokens

      render jsonapi: tokens
    end

    def show
      authorize! token

      render jsonapi: token
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash, optional: true do
        param :type, type: :string, inclusion: { in: %w[token tokens] }
        param :attributes, type: :hash do
          param :expiry, type: :time, allow_nil: true, optional: true, coerce: true
          param :name, type: :string, allow_nil: true, optional: true
        end
      end
      param :meta, type: :hash, optional: true do
        param :otp, type: :string
      end
    }
    def generate
      authenticate_with_http_basic do |email, password|
        user = current_account.users.find_by email: "#{email}".downcase

        if user&.second_factor_enabled?
          otp = token_meta[:otp]
          if otp.nil?
            return render_unauthorized detail: 'second factor is required', code: 'OTP_REQUIRED', source: { pointer: '/meta/otp' }
          end

          if !user.verify_second_factor(otp)
            return render_unauthorized detail: 'second factor must be valid', code: 'OTP_INVALID', source: { pointer: '/meta/otp' }
          end
        end

        if user&.password? && user.authenticate(password)
          authorize! with: TokenPolicy, context: { bearer: user }

          kwargs = token_params.slice(:expiry, :name)
          if !kwargs.key?(:expiry)
            # NOTE(ezekg) Admin tokens do not expire by default
            kwargs[:expiry] = user.has_role?(:user) ? Time.current + Token::TOKEN_DURATION : nil
          end

          token = TokenGeneratorService.call(
            account: current_account,
            bearer: user,
            **kwargs,
          )

          if token.valid?
            BroadcastEventService.call(
              event: 'token.generated',
              account: current_account,
              resource: token,
            )

            return render jsonapi: token, status: :created, location: v1_account_token_url(token.account, token)
          else
            return render_unprocessable_resource token
          end
        end

        return render_unauthorized detail: 'Credentials must be valid', code: 'CREDENTIALS_INVALID'
      end

      render_unauthorized detail: 'An email and password is required', code: 'CREDENTIALS_REQUIRED'
    rescue ArgumentError # Catch null bytes (Postgres throws an argument error)
      render_bad_request
    end

    # FIXME(ezekg) Deprecate this route.
    def regenerate_current
      raise Keygen::Error::NotFoundError.new(model: Token.name) unless
        current_token.present?

      authorize! current_token,
        to: :regenerate?

      current_token.regenerate!

      BroadcastEventService.call(
        event: 'token.regenerated',
        account: current_account,
        resource: current_token,
      )

      render jsonapi: current_token
    end

    def regenerate
      authorize! token

      token.regenerate!

      BroadcastEventService.call(
        event: 'token.regenerated',
        account: current_account,
        resource: token,
      )

      render jsonapi: token
    end

    def revoke
      authorize! token

      BroadcastEventService.call(
        event: 'token.revoked',
        account: current_account,
        resource: token,
      )

      token.destroy_async
    end

    private

    attr_reader :token

    def set_token
      scoped_tokens = authorized_scope(current_account.tokens)

      @token = scoped_tokens.find(params[:id])

      Current.resource = token
    end
  end
end
