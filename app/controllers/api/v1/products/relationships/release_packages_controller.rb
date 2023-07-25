# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ReleasePackagesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:engine)  { |c, s, v| s.for_engine(v) }

    authorize :product

    def index
      packages = apply_pagination(authorized_scope(apply_scopes(product.release_packages)))
      authorize! packages,
        with: Products::ReleasePackagePolicy

      render jsonapi: packages
    end

    def show
      package = product.release_packages.find(params[:id])
      authorize! package,
        with: Products::ReleasePackagePolicy

      render jsonapi: package
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
