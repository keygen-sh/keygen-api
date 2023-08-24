# frozen_string_literal: true

module Api::V1::Machines::Relationships
  class MachineComponentsController < Api::V1::BaseController
    has_scope(:status) { |c, s, v| s.with_status(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    authorize :machine

    def index
      machine_components = apply_pagination(authorized_scope(apply_scopes(machine.components)).preload(:machine, :license, :policy, :product, :group))
      authorize! machine_components,
        with: Machines::MachineComponentPolicy

      render jsonapi: machine_components
    end

    def show
      machine_component = machine.components.find(params[:id])
      authorize! machine_component,
        with: Machines::MachineComponentPolicy

      render jsonapi: machine_component
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
