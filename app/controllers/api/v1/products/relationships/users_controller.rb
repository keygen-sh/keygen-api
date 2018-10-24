module Api::V1::Products::Relationships
  class UsersController < Api::V1::BaseController
    has_scope :roles, type: :array, default: [:user]

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    # GET /products/1/users
    def index
      @users = policy_scope apply_scopes(@product.users.preload(:role))
      authorize @users

      render jsonapi: @users
    end

    # GET /products/1/users/1
    def show
      @user = @product.users.find params[:id]
      authorize @user

      render jsonapi: @user
    end

    private

    def set_product
      @product = current_account.products.find params[:product_id]
      authorize @product, :show?
    end
  end
end
