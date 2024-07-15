# frozen_string_literal: true

module Api::V1::Products::Relationships
  class LicensesController < Api::V1::BaseController
    has_scope(:policy) { |c, s, v| s.for_policy(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }
    has_scope :suspended

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_product

    authorize :product

    def index
      licenses = apply_pagination(authorized_scope(apply_scopes(product.licenses)).preload(:role, :product, :policy, owner: %i[role]))
      authorize! licenses,
        with: Products::LicensePolicy

      render jsonapi: licenses
    end

    def show
      license = FindByAliasService.call(product.licenses, id: params[:id], aliases: :key)
      authorize! license,
        with: Products::LicensePolicy

      render jsonapi: license
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
