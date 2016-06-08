module Api::V1::Products::Relationships
  class UsersController < Api::V1::BaseController
    scope_by_subdomain

    before_action :set_product, only: [:create, :destroy]
    before_action :set_user, only: [:destroy]

    # accessible_by_admin :create, :destroy

    # POST /products/1/relationships/users
    def create
      @user = @current_account.users.find_by_hashid user_params

      if @user
        @product.users << @user
        render status: :created
      else
        render status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique
      render status: :conflict
    end

    # DELETE /products/1/relationships/users/2
    def destroy
      @product.users.delete @user if @product.users.include? @user
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
