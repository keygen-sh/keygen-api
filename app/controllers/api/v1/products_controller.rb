module Api::V1
  class ProductsController < Api::V1::BaseController
    has_scope :page, type: :hash

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_product, only: [:show, :update, :destroy]

    # GET /products
    def index
      @products = policy_scope apply_scopes(current_account.products).all
      authorize @products

      render json: @products
    end

    # GET /products/1
    def show
      render_not_found and return unless @product

      authorize @product

      render json: @product
    end

    # POST /products
    def create
      @product = current_account.products.new product_params
      authorize @product

      if @product.save
        CreateWebhookEventService.new(
          event: "product.created",
          account: current_account,
          resource: @product
        ).execute

        render json: @product, status: :created, location: v1_product_url(@product)
      else
        render_unprocessable_resource @product
      end
    end

    # PATCH/PUT /products/1
    def update
      render_not_found and return unless @product

      authorize @product

      if @product.update(product_params)
        CreateWebhookEventService.new(
          event: "product.updated",
          account: current_account,
          resource: @product
        ).execute

        render json: @product
      else
        render_unprocessable_resource @product
      end
    end

    # DELETE /products/1
    def destroy
      render_not_found and return unless @product

      authorize @product

      CreateWebhookEventService.new(
        event: "product.deleted",
        account: current_account,
        resource: @product
      ).execute

      @product.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = current_account.products.find_by_hashid params[:id]
    end

    # Only allow a trusted parameter "white list" through.
    def product_params
      params.require(:product).permit :name, :platforms => []
    end
  end
end
