module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_by_subdomain!

    def request_tokens
      skip_authorization

      authenticate_with_http_basic do |email, password|
        user = @current_account.users.find_by email: email

        if user&.authenticate(password)
          render json: user.token and return
        end
      end

      render_unauthorized({
        detail: "Invalid credentials given for email or password"
      })
    end

    def reset_tokens
      skip_authorization

      authenticate_with_http_token do |token, options|
        bearer = @current_account.tokens.find_by(reset_token: token)&.bearer
        bearer.token.reset! unless bearer.nil?

        if bearer&.token
          render json: bearer.token and return
        end
      end

      render_unauthorized detail: "must be a valid reset token", source: {
        pointer: "/data/attributes/token.resetToken" }
    end
  end
end
