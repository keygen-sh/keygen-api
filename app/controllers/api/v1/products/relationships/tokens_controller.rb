module Api::V1::Products::Relationships
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_by_subdomain!
    before_action :set_product

    def generate
      skip_authorization

      authenticate_with_http_token do |token, options|
        bearer = TokenAuthenticationService.new(
          account: @current_account,
          token: token
        ).authenticate

        if !bearer.nil? && bearer.has_role?(:admin)
          @product.token.generate!

          render json: @product.token and return
        end
      end

      render_unauthorized detail: "must be a valid admin token", source: {
        pointer: "/data/relationships/token" }
    end

    private

    def set_product
      @product = Product.find_by_hashid params[:product_id]
    end
  end
end
