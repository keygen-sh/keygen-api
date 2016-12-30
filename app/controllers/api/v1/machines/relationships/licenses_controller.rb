module Api::V1::Machines::Relationships
  class LicensesController < Api::V1::BaseController
    before_action :scope_to_current_account!
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
      @machine = current_account.machines.find params[:machine_id]
      authorize @machine, :show?
    end
  end
end
