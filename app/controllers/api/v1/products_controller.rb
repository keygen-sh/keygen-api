module Api::V1
  class ProductsController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_product, only: [:show, :update, :destroy]

    # accessible_by_admin :index, :show, :create, :update, :destroy

    # GET /products
    def index
      @products = @current_account.products.all
      authorize @products

      render json: @products
    end

    # GET /products/1
    def show
      authorize @product

      render json: @product
    end

    # POST /products
    def create
      @product = @current_account.products.new product_params
      authorize @product

      if @product.save
        render json: @product, status: :created, location: v1_product_url(@product)
      else
        render json: @product, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # PATCH/PUT /products/1
    def update
      authorize @product

      if @product.update(product_params)
        render json: @product
      else
        render json: @product, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # DELETE /products/1
    def destroy
      authorize @product

      @product.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = @current_account.products.find_by_hashid params[:id]
      @product || render_not_found
    end

    # Only allow a trusted parameter "white list" through.
    def product_params
      params.require(:product).permit :name, :platforms => []
    end
  end
end
