module Api::V1
  class ProductsController < ApiController
    before_action :set_product, only: [:show, :update, :destroy]

    scope_by_subdomain
    accessible_by_admin :index, :show, :create, :update, :destroy

    # GET /products
    def index
      @products = @current_account.products.all

      render json: @products
    end

    # GET /products/1
    def show
      render json: @product
    end

    # POST /products
    def create
      @product = @current_account.products.new product_params

      if @product.save
        render json: @product, status: :created, location: v1_product_url(@product)
      else
        render json: @product, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # PATCH/PUT /products/1
    def update
      if @product.update(product_params)
        render json: @product
      else
        render json: @product, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
      end
    end

    # DELETE /products/1
    def destroy
      @product.destroy
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_product
      @product = @current_account.products.find_by_hashid params[:id]
    end

    # Only allow a trusted parameter "white list" through.
    def product_params
      params.require(:product).permit :name, :platforms => []
    end
  end
end
