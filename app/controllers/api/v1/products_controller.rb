module Api::V1
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product, only: [:show, :update, :destroy]

    # GET /products
    def index
      @products = policy_scope apply_scopes(current_account.products)
      authorize @products

      render jsonapi: @products
    end

    # GET /products/1
    def show
      authorize @product

      render jsonapi: @product
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

        render jsonapi: @product, status: :created, location: v1_account_product_url(@product.account, @product)
      else
        render_unprocessable_resource @product
      end
    end

    # PATCH/PUT /products/1
    def update
      authorize @product

      if @product.update(product_params)
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
      authorize @product

      CreateWebhookEventService.new(
        event: "product.deleted",
        account: current_account,
        resource: @product
      ).execute

      @product.destroy_async
    end

    private

    def set_product
      @product = current_account.products.find params[:id]
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[product products]
          param :attributes, type: :hash do
            param :name, type: :string
            param :url, type: :string, optional: true
            param :metadata, type: :hash, optional: true
            param :platforms, type: :array, optional: true, allow_nil: true do
              items type: :string
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[product products]
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :url, type: :string, optional: true, allow_nil: true
            param :metadata, type: :hash, optional: true
            param :platforms, type: :array, optional: true, allow_nil: true do
              items type: :string
            end
          end
        end
      end
    end
  end
end
