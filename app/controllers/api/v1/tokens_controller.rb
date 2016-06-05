module Api::V1
  class TokensController < ApiController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    scope_by_subdomain

    def login
      authenticate_with_http_basic do |email, password|
        user = @current_account.users.find_by email: email

        if user && user.authenticate(password)
          render json: user, serializer: ActiveModel::Serializer::TokenSerializer
        else
          render status: :unauthorized
        end
      end
    end

    def reset
      authenticate_with_http_token do |token, options|
        user = @current_account.users.find_by reset_auth_token: token
        user.reset_auth_tokens! unless user.nil?

        if user
          render json: user, serializer: ActiveModel::Serializer::TokenSerializer
        else
          render status: :unauthorized
        end
      end
    end
  end
end
