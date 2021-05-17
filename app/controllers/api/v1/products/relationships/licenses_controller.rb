# frozen_string_literal: true

module Api::V1::Products::Relationships
  class LicensesController < Api::V1::BaseController
    has_scope(:policy) { |c, s, v| s.for_policy(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }
    has_scope :suspended

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    # GET /products/1/licenses
    def index
      @licenses = policy_scope apply_scopes(@product.licenses.preload(:policy))
      authorize @licenses

      render jsonapi: @licenses
    end

    # GET /products/1/licenses/1
    def show
      @license = FindByAliasService.call(scope: @product.licenses, identifier: params[:id], aliases: :key)
      authorize @license

      render jsonapi: @license
    end

    private

    def set_product
      @product = current_account.products.find params[:product_id]
      authorize @product, :show?

      Keygen::Store::Request.store[:current_resource] = @product
    end
  end
end
