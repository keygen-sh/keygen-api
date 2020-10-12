# frozen_string_literal: true

module Api::V1::Machines::Relationships
  class ProductsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    # GET /machines/1/product
    def show
      @product = @machine.product
      authorize @product

      render jsonapi: @product
    end

    private

    def set_machine
      @machine = current_account.machines.sluggable_find! params[:machine_id]
      authorize @machine, :show?
    end
  end
end
