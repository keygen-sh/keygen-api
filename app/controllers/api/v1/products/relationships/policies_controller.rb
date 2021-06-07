# frozen_string_literal: true

module Api::V1::Products::Relationships
  class PoliciesController < Api::V1::BaseController
    prepend_before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    # GET /products/1/policies
    def index
      @policies = policy_scope apply_scopes(@product.policies)
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

      Keygen::Store::Request.store[:current_resource] = @product
    end
  end
end
