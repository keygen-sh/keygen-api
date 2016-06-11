module Api::V1::Products::Relationships
  class UsersController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_product, only: [:create, :destroy]
    before_action :set_user, only: [:destroy]

    # POST /products/1/relationships/users
    def create
      authorize @product

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
      authorize @product

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
