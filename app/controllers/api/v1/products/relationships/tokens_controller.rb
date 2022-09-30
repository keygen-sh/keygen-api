# frozen_string_literal: true

module Api::V1::Products::Relationships
  class TokensController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    # POST /products/1/tokens
    def generate
      authorize product, :generate_token?

      token = TokenGeneratorService.call(
        account: current_account,
        bearer: product,
        expiry: nil
      )

      BroadcastEventService.call(
        event: "token.generated",
        account: current_account,
        resource: token
      )

      render jsonapi: token
    end

    # GET /products/1/tokens
    def index
      authorize product, :list_tokens?

      tokens = apply_pagination(policy_scope(apply_scopes(product.tokens)))
      authorize tokens

      render jsonapi: tokens
    end

    # GET /products/1/tokens/1
    def show
      authorize product, :show_token?

      token = product.tokens.find params[:id]
      authorize token

      render jsonapi: token
    end

    private

    attr_reader :product

    def set_product
      @product = current_account.products.find params[:product_id] || params[:id]
      authorize product, :show?

      Current.resource = product
    end
  end
end
