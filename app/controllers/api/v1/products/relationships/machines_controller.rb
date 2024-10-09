# frozen_string_literal: true

module Api::V1::Products::Relationships
  class MachinesController < Api::V1::BaseController
    has_scope(:fingerprint) { |c, s, v| s.with_fingerprint(v) }
    has_scope(:license) { |c, s, v| s.for_license(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_product

    authorize :product

    def index
      machines = apply_pagination(authorized_scope(apply_scopes(product.machines)).preload(:product, :policy, :owner, license: %i[owner]))
      authorize! machines,
        with: Products::MachinePolicy

      render jsonapi: machines
    end

    def show
      machine = FindByAliasService.call(product.machines, id: params[:id], aliases: :fingerprint)
      authorize! machine,
        with: Products::MachinePolicy

      render jsonapi: machine
    end

    private

    attr_reader :product

    def set_product
      scoped_products = authorized_scope(current_account.products)

      Current.resource = @product = FindByAliasService.call(
        scoped_products,
        id: params[:product_id],
        aliases: :code,
      )
    end
  end
end
