module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_to_current_account!
    before_action :require_active_subscription!, only: [:index]
    before_action :authenticate_with_token!, only: [:index, :show, :regenerate, :revoke]
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

        if user&.authenticate(password)
          kwargs = {
            expiry: if user.role?(:user)
                      Time.current + Token::TOKEN_DURATION
                    else
                      nil # Admin tokens don't expire
                    end
          }

          token = TokenGeneratorService.new(
            account: current_account,
            bearer: user,
            **kwargs
          ).execute

          render jsonapi: token, status: :created, location: v1_account_token_url(token.account, token) and return
        end
      end

      render_unauthorized detail: "credentials must be valid"
    rescue ArgumentError # Catch null bytes (Postgres throws an argument error)
      render_bad_request
    end

    # PUT /tokens
    def regenerate_current
      skip_authorization

      authenticate_with_http_token do |token, options|
        tok = TokenAuthenticationService.new(
          account: current_account,
          token: token
        ).execute

        next if tok.nil?

        if tok.expired?
          render_unauthorized detail: "is expired", source: {
            pointer: "/data/relationships/token" } and return
        end

        tok.regenerate!

        render jsonapi: tok and return
      end

      render_unauthorized detail: "must be a valid token"
    end

    # PUT /tokens/1
    def regenerate
      authorize @token

      @token.regenerate!

      render jsonapi: @token
    end

    # DELETE /tokens/1
    def revoke
      authorize @token

      @token.destroy_async
    end

    private

    def set_token
      @token = current_account.tokens.find params[:id]
    end
  end
end
