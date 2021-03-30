# frozen_string_literal: true

module Api::V1::Products::Relationships
  class MachinesController < Api::V1::BaseController
    has_scope :fingerprint
    has_scope :license
    has_scope :user

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    # GET /products/1/machines
    def index
      @machines = policy_scope apply_scopes(@product.machines.preload(:product, :policy))
      authorize @machines

      render jsonapi: @machines
    end

    # GET /products/1/machines/1
    def show
      @machine = FindByAliasService.new(@product.machines, params[:id], aliases: :fingerprint).call
      authorize @machine

      render jsonapi: @machine
    end

    private

    def set_product
      @product = current_account.products.find params[:product_id]
      authorize @product, :show?

      Keygen::Store::Request.store[:current_resource] = @product
    end
  end
end
