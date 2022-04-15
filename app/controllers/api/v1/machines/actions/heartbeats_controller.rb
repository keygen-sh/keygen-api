# frozen_string_literal: true

module Api::V1::Machines::Actions
  class HeartbeatsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine

    # POST /machines/1/reset-heartbeat
    def reset_heartbeat
      authorize machine

      machine.update!(last_heartbeat_at: nil)

      BroadcastEventService.call(
        event: 'machine.heartbeat.reset',
        account: current_account,
        resource: machine,
      )

      render jsonapi: machine
    end

    # POST /machines/1/ping-heartbeat
    def ping_heartbeat
      authorize machine

      if machine.dead?
        return render_unprocessable_entity(detail: 'is dead', code: 'MACHINE_HEARTBEAT_DEAD', source: { pointer: '/data/attributes/heartbeatStatus' }) unless
          machine.policy.resurrect_dead? && !machine.resurrection_period_passed?

        machine.resurrect!

        BroadcastEventService.call(
          event: 'machine.heartbeat.resurrected',
          account: current_account,
          resource: machine,
        )
      else
        machine.ping!

        BroadcastEventService.call(
          event: 'machine.heartbeat.ping',
          account: current_account,
          resource: machine,
        )
      end

      # Queue up heartbeat worker which will handle deactivating dead machines
      MachineHeartbeatWorker.perform_in(
        machine.heartbeat_duration + Machine::HEARTBEAT_DRIFT,
        machine.id,
      )

      render jsonapi: machine
    end

    private

    attr_reader :machine

    def set_machine
      scoped_machines = policy_scope(current_account.machines)

      @machine = FindByAliasService.call(scope: scoped_machines, identifier: params[:id], aliases: :fingerprint)

      Current.resource = machine
    end
  end
end
