# frozen_string_literal: true

module Api::V1::MachineProcesses::Relationships
  class LicensesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_machine_process

    authorize :machine_process

    def show
      license = machine_process.license
      authorize! license,
        with: MachineProcesses::LicensePolicy

      render jsonapi: license
    end

    private

    attr_reader :machine_process

    def set_machine_process
      scoped_machine_processes = authorized_scope(current_account.machine_processes)

      @machine_process = scoped_machine_processes.find(params[:machine_process_id])

      Current.resource = machine_process
    end
  end
end
