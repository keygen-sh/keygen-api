# frozen_string_literal: true

module Api::V1::Licenses::Relationships
  class MachinesController < Api::V1::BaseController
    has_scope :fingerprint
    has_scope :product
    has_scope :user

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
      @machine = FindByAliasService.new(@license.machines, params[:id], aliases: :fingerprint).call
      authorize @machine

      render jsonapi: @machine
    end

    private

    def set_license
      @license = FindByAliasService.new(current_account.licenses, params[:license_id], aliases: :key).call
      authorize @license, :show?

      Keygen::Store::Request.store[:current_resource] = @license
    end
  end
end
