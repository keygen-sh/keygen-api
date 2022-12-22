# frozen_string_literal: true

module Api::V1::Products::Relationships
  class UsersController < Api::V1::BaseController
    has_scope(:roles, type: :array, default: [:user]) { |c, s, v| s.with_roles(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    authorize :product

    def index
      users = apply_pagination(authorized_scope(apply_scopes(product.users)).preload(:role))
      authorize! users,
        with: Products::UserPolicy

      render jsonapi: users
    end

    def show
      user = FindByAliasService.call(product.users, id: params[:id], aliases: :email)
      authorize! user,
        with: Products::UserPolicy

      render jsonapi: user
    end

    private

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      @product = scoped_products.find(params[:product_id])

      Current.resource = product
    end
  end
end
