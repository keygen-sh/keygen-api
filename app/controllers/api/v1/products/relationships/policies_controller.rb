# frozen_string_literal: true

module Api::V1::Products::Relationships
  class PoliciesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    authorize :product

    def index
      policies = apply_pagination(authorized_scope(apply_scopes(product.policies)))
      authorize! policies,
        with: Products::PolicyPolicy

      render jsonapi: policies
    end

    def show
      policy = product.policies.find(params[:id])
      authorize! policy,
        with: Products::PolicyPolicy

      render jsonapi: policy
    end

    private

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = Current.resource = FindByAliasService.call(
        scoped_products,
        id: params[:product_id],
        aliases: :code,
      )
    end
  end
end
