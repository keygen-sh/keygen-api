# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ReleasePlatformsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    authorize :product

    def index
      platforms = apply_pagination(authorized_scope(apply_scopes(product.release_platforms)))
      authorize! platforms,
        with: Products::ReleasePlatformPolicy

      render jsonapi: platforms
    end

    def show
      platform = product.release_platforms.find(params[:id])
      authorize! platform,
        with: Products::ReleasePlatformPolicy

      render jsonapi: platform
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
