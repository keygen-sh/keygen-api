module Api::V1::Users::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    # GET /users/1/products
    def index
      @products = policy_scope apply_scopes(@user.products).all
      authorize @products

      render jsonapi: @products
    end

    # GET /users/1/products/1
    def show
      @product = @user.products.find params[:id]
      authorize @product

      render jsonapi: @product
    end

    private

    def set_user
      @user = current_account.users.find params[:user_id]
      authorize @user, :show?
    end
  end
end
