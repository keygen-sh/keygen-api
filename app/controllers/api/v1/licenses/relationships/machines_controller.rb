module Api::V1::Licenses::Relationships
  class MachinesController < Api::V1::BaseController
    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_license, only: [:create, :destroy]
    before_action :set_machine, only: [:destroy]

    # POST /licenses/1/relationships/machines
    def create
      render_not_found and return unless @license

      authorize @license

      @machine = machine_params.to_h

      # TODO: Make sure they don't go over the policy's max_activations
      if @license.active_machines.include? @machine
        render_conflict detail: "already exists", source: {
          pointer: "/data/attributes/activeMachines.machine" }
      else
        @license.active_machines << @machine

        if @license.save
          head :created
        else
          render_unprocessable_resource @license
        end
      end
    end

    # DELETE /licenses/1/relationships/machines/2
    def destroy
      render_not_found and return unless @license

      authorize @license

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
      params.require(:machine).permit :fingerprint, {
        meta: [:ip, :hostname, :platform]
      }
    end
  end
end
