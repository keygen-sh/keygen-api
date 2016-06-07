module Api::V1::Licenses::Relationships
  class MachinesController < BaseController
    scope_by_subdomain

    before_action :set_license, only: [:create, :destroy]
    before_action :set_machine, only: [:destroy]

    # accessible_by_admin :create, :destroy

    # POST /licenses/1/relationships/machines
    def create
      @machine = machine_params.to_h

      if @license.active_machines.include? @machine
        render status: :conflict
      else
        @license.active_machines << @machine

        if @license.save
          render status: :created
        else
          render json: @license, status: :unprocessable_entity, adapter: :json_api, serializer: ActiveModel::Serializer::ErrorSerializer
        end
      end
    end

    # DELETE /licenses/1/relationships/machines/2
    def destroy
      @machine = params[:id]

      @license.active_machines.reject! { |m| m[:fingerprint] == @machine }
      @license.save
    end

    private

    def set_license
      @license = @current_account.licenses.find_by_hashid params[:license_id]
    end

    def set_machine
      @machine = params[:id]
    end

    def machine_params
      params.require(:machine).permit :fingerprint, :meta => {}
    end
  end
end
