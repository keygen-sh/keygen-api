module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_to_current_account!
    before_action :authenticate_with_token!, only: [:index, :show, :regenerate, :revoke]
    before_action :set_token, only: [:show, :regenerate, :revoke]

    # GET /tokens
    def index
      @tokens = policy_scope apply_scopes(current_bearer.tokens).all
      authorize @tokens

      render json: @tokens
    end

    # GET /tokens/1
    def show
      render_not_found and return unless @token

      authorize @token

      render json: @token
    end

    # POST /tokens
    def generate
      skip_authorization

      authenticate_with_http_basic do |email, password|
        user = current_account.users.find_by email: email

        if user&.authenticate(password)
          token = TokenGeneratorService.new(
            account: current_account,
            bearer: user
          ).execute

          render json: token and return
        end
      end

      render_unauthorized detail: "credentials must be valid"
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

        render json: tok and return
      end

      render_unauthorized detail: "must be a valid token", source: {
        pointer: "/data/relationships/token" }
    end

    # PUT /tokens/1
    def regenerate
      render_not_found and return unless @token

      authorize @token

      @token.regenerate!

      render json: @token and return
    end

    # DELETE /tokens/1
    def revoke
      render_not_found and return unless @token

      authorize @token

      @token.destroy
    end

    private

    def set_token
      @token = current_account.tokens.find_by_hashid params[:id]
    end
  end
end
