module Api::V1::Licenses::Relationships
  class MachinesController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_license

    # GET /licenses/1/machines
    def index
      @machines = policy_scope apply_scopes(@license.machines).all
      authorize @machines

      render jsonapi: @machines
    end

    # GET /licenses/1/machines/1
    def show
      @machine = @license.machines.find params[:id]
      authorize @machine

      render jsonapi: @machine
    end

    private

    def set_license
      @license = current_account.licenses.find params[:license_id]
      authorize @license, :show?
    end
  end
end
