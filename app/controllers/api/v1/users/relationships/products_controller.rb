# frozen_string_literal: true

module Api::V1::Users::Relationships
  class ProductsController < Api::V1::BaseController
    prepend_before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    # GET /users/1/products
    def index
      @products = policy_scope apply_scopes(@user.products)
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
      @user = FindByAliasService.new(current_account.users, params[:user_id], aliases: :email).call
      authorize @user, :show?

      Keygen::Store::Request.store[:current_resource] = @user
    end
  end
end
