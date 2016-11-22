module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!, only: [:index, :show, :revoke]
    before_action :set_token, only: [:show, :revoke]

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
    def regenerate
      skip_authorization

      authenticate_with_http_token do |token, options|
        token = TokenAuthenticationService.new(
          account: current_account,
          token: token
        ).execute

        next if token.nil?

        if token.expired?
          render_unauthorized detail: "is expired", source: {
            pointer: "/data/relationships/token" } and return
        end

        token.regenerate!

        render json: token and return
      end

      render_unauthorized detail: "must be a valid token", source: {
        pointer: "/data/relationships/token" }
    end

    # DELETE /tokens
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
