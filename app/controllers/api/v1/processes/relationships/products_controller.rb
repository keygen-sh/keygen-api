# frozen_string_literal: true

module Api::V1::Processes::Relationships
  class ProductsController < Api::V1::BaseController
    supports_environment

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine_process

    authorize :machine_process

    def show
      product = machine_process.product
      authorize! product,
        with: MachineProcesses::ProductPolicy

      render jsonapi: product
    end

    private

    attr_reader :machine_process

    def set_machine_process
      scoped_machine_processes = authorized_scope(current_account.machine_processes)

      @machine_process = scoped_machine_processes.find(params[:process_id])

      Current.resource = machine_process
    end
  end
end
