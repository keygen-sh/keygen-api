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
      @machine =
        if params[:machine_id] =~ UUID_REGEX
          current_account.machines.find_by id: params[:machine_id]
        else
          current_account.machines.find_by fingerprint: params[:machine_id]
        end

      raise Keygen::Error::NotFoundError.new(model: Machine.name, id: params[:machine_id]) if @machine.nil?

      authorize @machine, :show?
    end
  end
end
