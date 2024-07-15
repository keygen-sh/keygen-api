# frozen_string_literal: true

module Api::V1::MachineComponents::Relationships
  class LicensesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_machine_component

    authorize :machine_component

    def show
      license = machine_component.license
      authorize! license,
        with: MachineComponents::LicensePolicy

      render jsonapi: license
    end

    private

    attr_reader :machine_component

    def set_machine_component
      scoped_machine_components = authorized_scope(current_account.machine_components)

      @machine_component = scoped_machine_components.find(params[:machine_component_id])

      Current.resource = machine_component
    end
  end
end
