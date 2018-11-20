module Api::V1::Licenses::Relationships
  class MachinesController < Api::V1::BaseController
    has_scope :fingerprint
    has_scope :product
    has_scope :user

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_license

    # GET /licenses/1/machines
    def index
      @machines = policy_scope apply_scopes(@license.machines.preload(:product))
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
      @license =
        if params[:license_id] =~ UUID_REGEX
          current_account.licenses.find_by id: params[:license_id]
        else
          current_account.licenses.find_by key: params[:license_id]
        end

      raise Keygen::Error::NotFoundError.new(model: License.name, id: params[:license_id]) if @license.nil?

      authorize @license, :show?
    end
  end
end
