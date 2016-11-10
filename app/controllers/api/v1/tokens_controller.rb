module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!, only: [:revoke]
    before_action :set_token, only: [:revoke]

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

    def regenerate
      skip_authorization

      authenticate_with_http_token do |token, options|
        token = TokenAuthenticationService.new(
          account: current_account,
          token: token
        ).execute

        if !token.nil?
          token.regenerate!

          render json: token and return
        end
      end

      render_unauthorized detail: "must be a valid token", source: {
        pointer: "/data/relationships/token" }
    end

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
