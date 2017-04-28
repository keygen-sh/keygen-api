module Api::V1::Keys::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_key

    # GET /keys/1/product
    def show
      @product = @key.product
      authorize @product

      render jsonapi: @product
    end

    private

    def set_key
      @key = current_account.keys.find params[:key_id]
      authorize @key, :show?
    end
  end
end
