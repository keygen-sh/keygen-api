module Api::V1
  class MachinesController < Api::V1::BaseController
    has_scope :fingerprint
    has_scope :product
    has_scope :license
    has_scope :user

    before_action :scope_to_current_account!
    before_action :authenticate_with_token!
    before_action :set_machine, only: [:show, :update, :destroy]

    # GET /machines
    def index
      @machines = policy_scope apply_scopes(current_account.machines).all
      authorize @machines

      render jsonapi: @machines
    end

    # GET /machines/1
    def show
      render_not_found and return unless @machine

      authorize @machine

      render jsonapi: @machine
    end

    # POST /machines
    def create
      @machine = current_account.machines.new machine_params
      authorize @machine

      if @machine.save
        CreateWebhookEventService.new(
          event: "machine.created",
          account: current_account,
          resource: @machine
        ).execute

        render jsonapi: @machine, status: :created, location: v1_account_machine_url(@machine.account, @machine)
      else
        render_unprocessable_resource @machine
      end
    end

    # PATCH/PUT /machines/1
    def update
      render_not_found and return unless @machine

      authorize @machine

      if @machine.update(machine_params)
        CreateWebhookEventService.new(
          event: "machine.updated",
          account: current_account,
          resource: @machine
        ).execute

        render jsonapi: @machine
      else
        render_unprocessable_resource @machine
      end
    end

    # DELETE /machines/1
    def destroy
      render_not_found and return unless @machine

      authorize @machine

      CreateWebhookEventService.new(
        event: "machine.deleted",
        account: current_account,
        resource: @machine
      ).execute

      @machine.destroy
    end

    private

    attr_reader :parameters

    def set_machine
      @machine = current_account.machines.find_by id: params[:id]
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[machine machines]
          param :attributes, type: :hash do
            param :fingerprint, type: :string
            param :name, type: :string, optional: true
            param :ip, type: :string, optional: true
            param :hostname, type: :string, optional: true
            param :platform, type: :string, optional: true
            param :metadata, type: :hash, optional: true
          end
          param :relationships, type: :hash do
            param :license, type: :hash do
              param :data, type: :hash do
                param :type, type: :string, inclusion: %w[license licenses]
                param :id, type: :string
              end
            end
          end
        end
      end

      on :update do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[machine machines]
          param :attributes, type: :hash do
            param :name, type: :string, optional: true
            param :ip, type: :string, optional: true
            param :hostname, type: :string, optional: true
            param :platform, type: :string, optional: true
            if current_bearer&.role? :admin or current_bearer&.role? :product
              param :metadata, type: :hash, optional: true
            end
          end
        end
      end
    end
  end
end
