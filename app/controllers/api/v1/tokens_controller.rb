module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_by_subdomain!

    def generate
      skip_authorization

      authenticate_with_http_basic do |email, password|
        user = @current_account.users.find_by email: email

        if user&.authenticate(password)
          user.token.generate!

          render json: user.token and return
        end
      end

      render_unauthorized detail: "credentials must be valid"
    end

    def regenerate
      skip_authorization

      authenticate_with_http_token do |token, options|
        bearer = TokenAuthenticationService.new(
          account: @current_account,
          token: token
        ).execute

        if !bearer.nil?
          bearer.token.generate!

          render json: bearer.token and return
        end
      end

      render_unauthorized detail: "must be a valid token", source: {
        pointer: "/data/relationships/token" }
    end
  end
end
