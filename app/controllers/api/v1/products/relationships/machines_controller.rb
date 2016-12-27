module Api::V1::Products::Relationships
  class MachinesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_product

    # GET /products/1/machines
    def index
      @machines = policy_scope apply_scopes(@product.machines).all
      authorize @machines

      render jsonapi: @machines
    end

    # GET /products/1/machines/1
    def show
      @machine = @product.machines.find params[:id]
      authorize @machine

      render jsonapi: @machine
    end

    private

    def set_product
      @product = current_account.products.find params[:product_id]
      authorize @product, :show?
    end
  end
end
