# frozen_string_literal: true

module Api::V1::Users::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_user

    authorize :user

    def index
      products = apply_pagination(authorized_scope(apply_scopes(user.products)).preload(:role))
      authorize! products,
        with: Users::ProductPolicy

      render jsonapi: products
    end

    def show
      product = user.products.find(params[:id])
      authorize! product,
        with: Users::ProductPolicy

      render jsonapi: product
    end

    private

    attr_reader :user

    def set_user
      scoped_users = authorized_scope(current_account.users)

      @user = FindByAliasService.call(scoped_users, id: params[:user_id], aliases: :email)

      Current.resource = user
    end
  end
end
