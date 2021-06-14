# frozen_string_literal: true

module Api::V1::Machines::Relationships
  class LicensesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    # GET /machines/1/license
    def show
      @license = @machine.license
      authorize @license

      render jsonapi: @license
    end

    private

    def set_machine
      @machine = FindByAliasService.call(scope: current_account.machines, identifier: params[:machine_id], aliases: :fingerprint)
      authorize @machine, :show?

      Keygen::Store::Request.store[:current_resource] = @machine
    end
  end
end
