# frozen_string_literal: true

module Api::V1
  class MachineProcessesController < Api::V1::BaseController
    has_scope(:product) { |c, s, v| s.for_product(v) }
    has_scope(:machine) { |c, s, v| s.for_machine(v) }
    has_scope(:license) { |c, s, v| s.for_license(v) }
    has_scope(:user) { |c, s, v| s.for_user(v) }
    has_scope(:status) { |c, s, v| s.with_status(v) }

    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine_process, only: %i[show update destroy]

    def index
      machine_processes = apply_pagination(authorized_scope(apply_scopes(current_account.machine_processes)).preload(:machine, :license, :policy, :product, :group, :user))
      authorize! machine_processes

      render jsonapi: machine_processes
    end

    def show
      authorize! machine_process

      render jsonapi: machine_process
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[process processes] }
        param :id, type: :string, optional: true
        param :attributes, type: :hash do
          param :pid, type: :string
          param :metadata, type: :metadata, allow_blank: true, optional: true
        end
        param :relationships, type: :hash do
          param :machine, type: :hash do
            param :data, type: :hash do
              param :type, type: :string, inclusion: { in: %w[machine machines] }
              param :id, type: :string
            end
          end

          Keygen.ee do |license|
            next unless
              license.entitled?(:environments)

            param :environment, type: :hash, optional: true do
              param :data, type: :hash, allow_nil: true do
                param :type, type: :string, inclusion: { in: %w[environment environments] }
                param :id, type: :string
              end
            end
          end
        end
      end
    }
    def create
      machine_process = current_account.machine_processes.new(machine_process_params)
      authorize! machine_process

      if machine_process.save
        jid = ProcessHeartbeatWorker.perform_in(
          machine_process.interval + MachineProcess::HEARTBEAT_DRIFT,
          machine_process.id,
        )

        machine_process.update(
          heartbeat_jid: jid,
        )

        BroadcastEventService.call(
          event: 'process.created',
          account: current_account,
          resource: machine_process,
        )

        render jsonapi: machine_process, status: :created, location: v1_account_machine_process_url(machine_process.account, machine_process)
      else
        render_unprocessable_resource(machine_process)
      end
    end

    typed_params {
      format :jsonapi

      param :data, type: :hash do
        param :type, type: :string, inclusion: { in: %w[process processes] }
        param :id, type: :string, optional: true, noop: true
        param :attributes, type: :hash do
          param :metadata, type: :metadata, allow_blank: true, optional: true, if: -> { current_bearer&.has_role?(:admin, :developer, :sales_agent, :support_agent, :product, :environment) }
        end
      end
    }
    def update
      authorize! machine_process

      if machine_process.update(machine_process_params)
        BroadcastEventService.call(
          event: 'process.updated',
          account: current_account,
          resource: machine_process,
        )

        render jsonapi: machine_process
      else
        render_unprocessable_resource(machine_process)
      end
    end

    def destroy
      authorize! machine_process

      BroadcastEventService.call(
        event: 'process.deleted',
        account: current_account,
        resource: machine_process,
      )

      machine_process.destroy
    end

    private

    # FIXME(ezekg) We're using :machine_process here because Rails has
    #              an internal :process method that conflicts.
    attr_reader :machine_process

    def set_machine_process
      scoped_processes = authorized_scope(current_account.machine_processes)

      @machine_process = scoped_processes.find(params[:id])

      Current.resource = machine_process
    end
  end
end
