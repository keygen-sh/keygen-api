module Api::V1
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_by_subdomain!

    def login
      skip_authorization

      authenticate_with_http_basic do |email, password|
        user = @current_account.users.find_by email: email

        if user&.authenticate(password)
          render json: user, serializer: ActiveModel::Serializer::TokenSerializer and return
        end
      end

      render_unauthorized({
        detail: "Invalid credentials given for email or password"
      }, "Basic")
    end

    def reset_tokens
      skip_authorization

      authenticate_with_http_token do |token, options|
        user = @current_account.users.find_by reset_auth_token: token
        user.reset_auth_tokens! unless user.nil?

        if user
          render json: user, serializer: ActiveModel::Serializer::TokenSerializer and return
        end
      end

      render_unauthorized detail: "must be a valid reset token", source: {
        pointer: "/data/attributes/resetAuthToken" }
    end
  end
end
