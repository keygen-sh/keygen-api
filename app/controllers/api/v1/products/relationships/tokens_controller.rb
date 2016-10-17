module Api::V1::Products::Relationships
  class TokensController < Api::V1::BaseController
    include ActionController::HttpAuthentication::Basic::ControllerMethods
    include ActionController::HttpAuthentication::Token::ControllerMethods

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_product

    def generate
      authorize @product

      @product.token.generate!

      render json: @product.token
    end

    private

    def set_product
      @product = Product.find_by_hashid params[:product_id]
    end
  end
end
