module Api::V1
  class MachinesController < Api::V1::BaseController
    has_scope :fingerprint
    has_scope :ip
    has_scope :hostname
    has_scope :product
    has_scope :policy
    has_scope :license
    has_scope :key
    has_scope :user

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine, only: [:show, :update, :destroy]

    # GET /machines
    def index
      @machines = policy_scope apply_scopes(current_account.machines.preload(:product))
      authorize @machines

      render jsonapi: @machines
    end

    # GET /machines/1
    def show
      authorize @machine

      render jsonapi: @machine
    end

    # POST /machines
    def create
      @machine = current_account.machines.new machine_params
      authorize @machine

      if @machine.valid? && current_token.activation_token?
        begin
          current_token.with_lock "FOR UPDATE NOWAIT" do
            current_token.increment :activations
            current_token.save!
          end
        rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
          return render_unprocessable_resource current_token
        rescue ActiveRecord::StaleObjectError, ActiveRecord::StatementInvalid # Thrown when update is attempted on locked row i.e. from FOR UPDATE NOWAIT
          return render_conflict detail: "failed to increment due to another conflicting activation", source: { pointer: "/data/attributes/activations" }
        rescue ActiveModel::RangeError
          return render_bad_request detail: "integer is too large", source: { pointer: "/data/attributes/activations" }
        end
      end

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
      authorize @machine

      if current_token.activation_token?
        begin
          current_token.with_lock "FOR UPDATE NOWAIT" do
            current_token.increment :deactivations
            current_token.save!
          end
        rescue ActiveRecord::RecordNotSaved, ActiveRecord::RecordInvalid
          return render_unprocessable_resource current_token
        rescue ActiveRecord::StaleObjectError, ActiveRecord::StatementInvalid
          return render_conflict detail: "failed to increment due to another conflicting deactivation", source: { pointer: "/data/attributes/deactivations" }
        rescue ActiveModel::RangeError
          return render_bad_request detail: "integer is too large", source: { pointer: "/data/attributes/deactivations" }
        end
      end

      CreateWebhookEventService.new(
        event: "machine.deleted",
        account: current_account,
        resource: @machine
      ).execute

      @machine.destroy
    end

    private

    def set_machine
      @machine = current_account.machines.find params[:id]
    end

    typed_parameters transform: true do
      options strict: true

      on :create do
        param :data, type: :hash do
          param :type, type: :string, inclusion: %w[machine machines]
          param :attributes, type: :hash do
            param :fingerprint, type: :string
            param :name, type: :string, optional: true, allow_nil: true
            param :ip, type: :string, optional: true, allow_nil: true
            param :hostname, type: :string, optional: true, allow_nil: true
            param :platform, type: :string, optional: true, allow_nil: true
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
          param :id, type: :string, inclusion: [controller.params[:id]], optional: true, transform: -> (k, v) { [] }
          param :attributes, type: :hash do
            param :name, type: :string, optional: true, allow_nil: true
            param :ip, type: :string, optional: true, allow_nil: true
            param :hostname, type: :string, optional: true, allow_nil: true
            param :platform, type: :string, optional: true, allow_nil: true
            if current_bearer&.role? :admin or current_bearer&.role? :product
              param :metadata, type: :hash, optional: true
            end
          end
        end
      end
    end
  end
end
