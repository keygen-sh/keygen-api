module Api::V1::Products::Relationships
  class UsersController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_product, only: [:create, :destroy]
    before_action :set_user, only: [:destroy]

    # POST /products/1/relationships/users
    def create
      render_not_found and return unless @product

      authorize @product

      @user = @current_account.users.find_by_hashid user_params

      if @user
        @product.users << @user

        WebhookEventService.new("product.user.added", {
          account: @current_account,
          resource: @user
        }).fire

        head :created
      else
        render_unprocessable_entity detail: "must exist", source: {
          pointer: "/data/attributes/users.user" }
      end
    rescue ActiveRecord::RecordNotUnique
      render_unprocessable_resource @product
    end

    # DELETE /products/1/relationships/users/2
    def destroy
      render_not_found and return unless @product

      authorize @product

      if @product.users.include?(@user)
        @product.users.delete @user

        WebhookEventService.new("product.user.removed", {
          account: @current_account,
          resource: @user
        }).fire
      end
    end

    private

    def set_product
      @product = @current_account.products.find_by_hashid params[:product_id]
    end

    def set_user
      @user = @current_account.users.find_by_hashid params[:id]
    end

    def user_params
      params.require :user
    end
  end
end
