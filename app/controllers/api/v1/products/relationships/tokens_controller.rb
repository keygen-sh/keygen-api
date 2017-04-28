module Api::V1::Products::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    # POST /products/1/tokens
    def generate
      authorize @product

      token = TokenGeneratorService.new(
        account: current_account,
        bearer: @product,
        expiry: false
      ).execute

      render jsonapi: token
    end

    # GET /products/1/tokens
    def index
      authorize @product, :show?

      @tokens = policy_scope apply_scopes(@product.tokens).all
      authorize @tokens

      render jsonapi: @tokens
    end

    # GET /products/1/tokens/1
    def show
      authorize @product

      @token = @product.tokens.find params[:id]
      authorize @token

      render jsonapi: @token
    end

    private

    def set_product
      @product = current_account.products.find params[:product_id] || params[:id]
    end
  end
end
