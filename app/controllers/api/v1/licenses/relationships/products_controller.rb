# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # GET /licenses/1/product
    def show
      @product = @license.product
      authorize @product

      render jsonapi: @product
    end

    private

    def set_license
      @license = FindByAliasService.call(scope: current_account.licenses, identifier: params[:license_id], aliases: :key)
      authorize @license, :show?

      Keygen::Store::Request.store[:current_resource] = @license
    end
  end
end
