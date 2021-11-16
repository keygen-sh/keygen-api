# frozen_string_literal: true

module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_to_current_account!
    before_action :require_active_subscription!, only: [:index]
    before_action :authenticate_with_token!, only: [:index, :show, :regenerate, :regenerate_current, :revoke]
    before_action :set_token, only: [:show, :regenerate, :revoke]

    # GET /tokens
    def index
      @tokens = policy_scope apply_scopes(current_account.tokens.preload(bearer: [:role]))
      authorize @tokens

      render jsonapi: @tokens
    end

    # GET /tokens/1
    def show
      authorize @token

      render jsonapi: @token
    end

    # POST /tokens
    def generate
      skip_authorization

      authenticate_with_http_basic do |email, password|
        user = current_account.users.find_by email: "#{email}".downcase

        if user&.second_factor_enabled?
          otp = token_meta[:otp]
          if otp.nil?
            render_unauthorized detail: 'second factor is required', code: 'OTP_REQUIRED', source: { pointer: '/meta/otp' } and return
          end

          if !user.verify_second_factor(otp)
            render_unauthorized detail: 'second factor must be valid', code: 'OTP_INVALID', source: { pointer: '/meta/otp' } and return
          end
        end

        if user&.authenticate(password)
          kwargs = token_params.to_h.symbolize_keys.slice(:expiry)
          if !kwargs.key?(:expiry)
            # NOTE(ezekg) Admin tokens do not expire by default
            kwargs[:expiry] = user.has_role?(:user) ? Time.current + Token::TOKEN_DURATION : nil
          end

          token = TokenGeneratorService.call(
            account: current_account,
            bearer: user,
            **kwargs
          )

          if token.valid?
            BroadcastEventService.call(
              event: 'token.generated',
              account: current_account,
              resource: token
            )

            return render jsonapi: token, status: :created, location: v1_account_token_url(token.account, token)
          else
            return render_unprocessable_resource token
          end
        end

        return render_unauthorized detail: 'Credentials must be valid', code: 'CREDENTIALS_INVALID'
      end

      render_unauthorized detail: 'Credentials must be provided', code: 'CREDENTIALS_MISSING'
    rescue ArgumentError # Catch null bytes (Postgres throws an argument error)
      render_bad_request
    end

    # PUT /tokens
    def regenerate_current
      authorize current_token, :regenerate?

      current_token.regenerate!

      BroadcastEventService.call(
        event: 'token.regenerated',
        account: current_account,
        resource: current_token,
      )

      render jsonapi: current_token
    end

    # PUT /tokens/1
    def regenerate
      authorize @token

      @token.regenerate!

      BroadcastEventService.call(
        event: "token.regenerated",
        account: current_account,
        resource: @token
      )

      render jsonapi: @token
    end

    # DELETE /tokens/1
    def revoke
      authorize @token

      BroadcastEventService.call(
        event: "token.revoked",
        account: current_account,
        resource: @token
      )

      @token.destroy_async
    end

    private

    def set_token
      @token = current_account.tokens.find params[:id]
    end

    typed_parameters format: :jsonapi do
      options strict: true

      on :generate do
        param :data, type: :hash, optional: true do
          param :type, type: :string, inclusion: %w[token tokens]
          param :attributes, type: :hash do
            param :expiry, type: :datetime, allow_nil: true, optional: true, coerce: true
          end
        end
        param :meta, type: :hash, optional: true do
          param :otp, type: :string
        end
      end
    end
  end
end
