# frozen_string_literal: true

module Api::V1::Machines::Relationships
  class LicensesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_machine

    authorize :machine

    def show
      license = machine.license
      authorize! license,
        with: Machines::LicensePolicy

      render jsonapi: license
    end

    private

    attr_reader :machine

    def set_machine
      scoped_machines = authorized_scope(current_account.machines)

      @machine = FindByAliasService.call(scoped_machines, id: params[:machine_id], aliases: :fingerprint)

      Current.resource = machine
    end
  end
end
