# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class MachinesController < Api::V1::BaseController
    has_scope(:fingerprint) { |c, s, v| s.with_fingerprint(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # GET /licenses/1/machines
    def index
      @machines = policy_scope apply_scopes(@license.machines.preload(:product, :policy))
      authorize @machines

      render jsonapi: @machines
    end

    # GET /licenses/1/machines/1
    def show
      @machine = FindByAliasService.call(scope: @license.machines, identifier: params[:id], aliases: :fingerprint)
      authorize @machine

      render jsonapi: @machine
    end

    private

    def set_license
      @license = FindByAliasService.call(scope: current_account.licenses, identifier: params[:license_id], aliases: :key)
      authorize @license, :show?

      Keygen::Store::Request.store[:current_resource] = @license
    end
  end
end
