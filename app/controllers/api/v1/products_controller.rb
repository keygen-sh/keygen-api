module Api::V1
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_product, only: [:show, :update, :destroy]

    # GET /products
    def index
      @products = policy_scope apply_scopes(current_account.products).all
      authorize @products

      render jsonapi: @products
    end

    # GET /products/1
    def show
      render_not_found and return unless @product

      authorize @product

      render jsonapi: @product, include: [:tokens]
    end

    # POST /products
    def create
      @product = current_account.products.new product_attributes
      authorize @product

      if @product.save
        CreateWebhookEventService.new(
          event: "product.created",
          account: current_account,
          resource: @product
        ).execute

        render jsonapi: @product, status: :created, location: v1_account_product_url(@product.account, @product)
      else
        render_unprocessable_resource @product
      end
    end

    # PATCH/PUT /products/1
    def update
      render_not_found and return unless @product

      authorize @product

      if @product.update(product_attributes)
        CreateWebhookEventService.new(
          event: "product.updated",
          account: current_account,
          resource: @product
        ).execute

        render jsonapi: @product
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

    def set_product
      @product = current_account.products.find_by id: params[:id]
    end

    def product_attributes
      parameters[:data][:attributes]
    end

    def parameters
      @parameters ||= TypedParameters.build self do
        options strict: true

        on :create do
          param :data, type: :hash do
            param :type, type: :string, inclusion: %w[product products]
            param :attributes, type: :hash do
              param :name, type: :string
              param :metadata, type: :hash, optional: true
              param :platforms, type: :array, optional: true do
                items type: :string
              end
            end
          end
        end

        on :update do
          param :data, type: :hash do
            param :type, type: :string, inclusion: %w[product products]
            param :attributes, type: :hash do
              param :name, type: :string, optional: true
              param :metadata, type: :hash, optional: true
              param :platforms, type: :array, optional: true do
                items type: :string
              end
            end
          end
        end
      end
    end
  end
end
