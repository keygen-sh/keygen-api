class ApplicationController < ActionController::API
  # include ActionController::HttpAuthentication::Basic::ControllerMethods
  # include ActionController::HttpAuthentication::Token::ControllerMethods

  # protected

  # def generate_token
  #   authenticate_with_http_basic do |email, password|
  #     user = User.find_by email: email
  #
  #     if user && user.authenticate(password)
  #       render json: { auth_token: user.auth_token,
  #         reset_auth_token: user.reset_auth_token }
  #     else
  #       render_unauthorized
  #     end
  #   end
  # end

  # def reset_token
  #   authenticate_with_http_token do |token, options|
  #     user = User.find_by reset_auth_token: token
  #     user.regenerate_auth_tokens unless user.nil?
  #
  #     if user
  #       render json: { auth_token: user.auth_token,
  #         reset_auth_token: user.reset_auth_token }
  #     else
  #       render_not_acceptable
  #     end
  #   end
  # end

  # def authenticate_with_token
  #   authenticate_with_http_token do |token, options|
  #     @current_user = User.find_by auth_token: token
  #   end
  # end

  # def render_unauthorized(message = nil, realm = "Application")
  #   self.headers["WWW-Authenticate"] = %(Token realm="#{realm.gsub(/"/, "")}")
  #   render json: {}, status: :unauthorized
  # end

  # def render_forbidden(message = nil)
  #   render json: {}, status: :forbidden
  # end

  # def render_not_acceptable(message = nil)
  #   render json: {}, status: :not_acceptable
  # end

  # def render_unprocessable_entity(message = nil)
  #   render json: {}, status: :unprocessable_entity
  # end

  # def render_not_found(message = nil)
  #   render json: {}, status: :not_found
  # end
end
