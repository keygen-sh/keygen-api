# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ReleaseArchesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    authorize :product

    def index
      arches = apply_pagination(authorized_scope(apply_scopes(product.release_arches)))
      authorize! arches,
        with: Products::ReleaseArchPolicy

      render jsonapi: arches
    end

    def show
      arch = product.release_arches.find(params[:id])
      authorize! arch,
        with: Products::ReleaseArchPolicy

      render jsonapi: arch
    end

    private

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = scoped_products.find(params[:product_id])

      Current.resource = product
    end
  end
end
