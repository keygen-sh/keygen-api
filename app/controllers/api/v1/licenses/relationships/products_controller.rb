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
      # FIXME(ezekg) This allows the license to be looked up by ID or
      #              key, but this is pretty messy.
      if params[:license_id] =~ UUID_REGEX
        id = params[:license_id]
      else
        key = params[:license_id]
      end

      @license = current_account.licenses.where("id = ? OR key = ?", id, key).first
      raise ActiveRecord::RecordNotFound if @license.nil?

      authorize @license, :show?
    end
  end
end
