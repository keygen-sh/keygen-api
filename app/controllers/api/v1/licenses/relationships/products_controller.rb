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
      @license =
        if params[:license_id] =~ UUID_REGEX
          current_account.licenses.find_by id: params[:license_id]
        else
          current_account.licenses.find_by key: params[:license_id]
        end

      raise Keygen::Error::NotFoundError.new(model: License.name, id: params[:license_id]) if @license.nil?

      authorize @license, :show?
    end
  end
end
