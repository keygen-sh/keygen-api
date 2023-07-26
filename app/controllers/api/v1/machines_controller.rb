# frozen_string_literal: true

module Api::V1
  class MachinesController < Api::V1::BaseController
    has_scope(:metadata, type: :hash, only: :index) { |c, s, v| s.with_metadata(v) }
    has_scope(:fingerprint) { |c, s, v| s.with_fingerprint(v) }
    has_scope(:ip) { |c, s, v| s.with_ip(v) }
    has_scope(:hostname) { |c, s, v| s.with_hostname(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:policy) { |c, s, v| s.for_policy(v) }
    has_scope(:license) { |c, s, v| s.for_license(v) }
    has_scope(:key) { |c, s, v| s.for_key(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }
    has_scope(:group) { |c, s, v| s.for_group(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine, only: [:show, :update, :destroy]

    def index
      machines = apply_pagination(authorized_scope(apply_scopes(current_account.machines)).preload(:product, :policy, :license, :user))
      authorize! machines

      render jsonapi: machines
    end

    def show
      authorize! machine

      render jsonapi: machine
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[machine machines] }
        param :id, type: :uuid, optional: true
        param :attributes, type: :hash do
          param :fingerprint, type: :string
          param :name, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :ip, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :hostname, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :platform, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :cores, type: :integer, allow_nil: true, optional: true
          param :metadata, type: :metadata, allow_blank: true, optional: true
        end
        param :relationships, type: :hash do
          param :license, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[license licenses] }
              param :id, type: :uuid
            end
          end
          param :group, type: :hash, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :environment) } do
            param :data, type: :hash, allow_nil: true do
              param :type, type: :string, inclusion: { in: %w[group groups] }
              param :id, type: :uuid
            end
          end

          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: { in: %w[environment environments] }
                param :id, type: :uuid
              end
            end
          end
        end
      end
    }
    def create
      machine = current_account.machines.new(machine_params)
      authorize! machine

      if machine.valid? && current_token&.activation_token?
        begin
          lock = if current_token.max_activations?
                   'FOR UPDATE NOWAIT'
                 else
                   'FOR UPDATE SKIP LOCKED'
                 end

          current_token.with_lock lock do
            current_token.increment :activations
            current_token.save!
          end
        rescue ActiveRecord::LockWaitTimeout, # NOWAIT raises timeout error
               ActiveRecord::RecordNotFound   # SKIP LOCKED raises not found
          # noop
        rescue ActiveRecord::RecordNotSaved,
               ActiveRecord::RecordInvalid
          return render_unprocessable_resource current_token
        rescue ActiveRecord::StaleObjectError,
               ActiveRecord::StatementInvalid # NOWAIT raises lock error
          return render_conflict detail: "failed to increment due to another conflicting activation", source: { pointer: "/data/attributes/activations" }
        rescue ActiveModel::RangeError
          return render_bad_request detail: "integer is too large", source: { pointer: "/data/attributes/activations" }
        end
      end

      if machine.save
        if machine.requires_heartbeat?
          jid = MachineHeartbeatWorker.perform_in(
            machine.heartbeat_duration + Machine::HEARTBEAT_DRIFT,
            machine.id,
          )

          machine.update(
            heartbeat_jid: jid,
          )
        end

        BroadcastEventService.call(
          event: 'machine.created',
          account: current_account,
          resource: machine
        )

        render jsonapi: machine, status: :created, location: v1_account_machine_url(machine.account, machine)
      else
        render_unprocessable_resource machine
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[machine machines] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :name, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :ip, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :hostname, type: :string, allow_blank: true, allow_nil: true, optional: true
          param :platform, type: :string, allow_blank: true, allow_nil: true, optional: true
          with if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :product, :environment) } do
            param :cores, type: :integer, allow_nil: true, optional: true
            param :metadata, type: :metadata, allow_blank: true, optional: true
          end
        end
      end
    }
    def update
      authorize! machine

      if machine.update(machine_params)
        BroadcastEventService.call(
          event: "machine.updated",
          account: current_account,
          resource: machine
        )

        render jsonapi: machine
      else
        render_unprocessable_resource machine
      end
    end

    def destroy
      authorize! machine

      if current_token&.activation_token?
        begin
          lock = if current_token.max_deactivations?
                   'FOR UPDATE NOWAIT'
                 else
                   'FOR UPDATE SKIP LOCKED'
                 end

          current_token.with_lock lock do
            current_token.increment :deactivations
            current_token.save!
          end
        rescue ActiveRecord::LockWaitTimeout, # NOWAIT raises timeout error
               ActiveRecord::RecordNotFound   # SKIP LOCKED raises not found
          # noop
        rescue ActiveRecord::RecordNotSaved,
               ActiveRecord::RecordInvalid
          return render_unprocessable_resource current_token
        rescue ActiveRecord::StaleObjectError,
               ActiveRecord::StatementInvalid # NOWAIT raises lock error
          return render_conflict detail: "failed to increment due to another conflicting deactivation", source: { pointer: "/data/attributes/deactivations" }
        rescue ActiveModel::RangeError
          return render_bad_request detail: "integer is too large", source: { pointer: "/data/attributes/deactivations" }
        end
      end

      BroadcastEventService.call(
        event: "machine.deleted",
        account: current_account,
        resource: machine
      )

      machine.destroy
    end

    private

    attr_reader :machine

    def set_machine
      scoped_machines = authorized_scope(current_account.machines)

      @machine = FindByAliasService.call(scoped_machines, id: params[:id], aliases: :fingerprint)

      Current.resource = machine
    end
  end
end
