module Api::V1::Products::Relationships
  class PoliciesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_product

    # GET /products/1/policies
    def index
      @policies = policy_scope apply_scopes(@product.policies).all
      authorize @policies

      render jsonapi: @policies
    end

    # GET /products/1/policies/1
    def show
      @policy = @product.policies.find params[:id]
      authorize @policy

      render jsonapi: @policy
    end

    private

    def set_product
      @product = current_account.products.find params[:product_id]
      authorize @product, :show?
    end
  end
end
