# frozen_string_literal: true

module Api::V1::Products::Relationships
  class ArchesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    def index
      arches = apply_pagination(policy_scope(apply_scopes(product.release_arches)))
      authorize arches

      render jsonapi: arches
    end

    def show
      arch = product.release_arches.find(params[:id])
      authorize arch

      render jsonapi: arch
    end

    private

    attr_reader :product

    def set_product
      @product = current_account.products.find(params[:product_id])
      authorize product, :show?

      Current.resource = product
    end
  end
end
