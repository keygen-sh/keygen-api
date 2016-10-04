module Api::V1
  class MachinesController < Api::V1::BaseController
    has_scope :license
    has_scope :user
    has_scope :page, type: :hash

    before_action :scope_by_subdomain!
    before_action :authenticate_with_token!
    before_action :set_machine, only: [:show, :update, :destroy]

    # GET /machines
    def index
      @machines = policy_scope apply_scopes(@current_account.machines).all
      authorize @machines

      render json: @machines
    end

    # GET /machines/1
    def show
      render_not_found and return unless @machine

      authorize @machine

      render json: @machine
    end

    # POST /machines
    def create
      license = @current_account.licenses.find_by_hashid machine_params[:license]

      @machine = @current_account.machines.new machine_params.merge(license: license)
      authorize @machine

      if @machine.save
        WebhookEventService.new("machine.created", {
          account: @current_account,
          resource: @machine
        }).fire

        render json: @machine, status: :created, location: v1_machine_url(@machine)
      else
        render_unprocessable_resource @machine
      end
    end

    # PATCH/PUT /machines/1
    def update
      render_not_found and return unless @machine

      authorize @machine

      if @machine.update(machine_params)
        WebhookEventService.new("machine.updated", {
          account: @current_account,
          resource: @machine
        }).fire

        render json: @machine
      else
        render_unprocessable_resource @machine
      end
    end

    # DELETE /machines/1
    def destroy
      render_not_found and return unless @machine

      authorize @machine

      WebhookEventService.new("machine.deleted", {
        account: @current_account,
        resource: @machine
      }).fire

      @machine.destroy
    end

    private

    def set_machine
      @machine = Machine.find_by_hashid params[:id]
    end

    def machine_params
      permitted_params
    end

    attr_accessor :permitted_params

    def permitted_params
      @permitted_params ||= Proc.new do
        schema = params.require(:machine).tap do |param|
          permits = []

          if action_name == "create"
            permits << :fingerprint
            permits << :ip
            permits << :hostname
            permits << :platform
            permits << :license
          end

          permits << :name

          param.permit *permits
        end.to_unsafe_hash

        schema
      end.call
    end
  end
end
