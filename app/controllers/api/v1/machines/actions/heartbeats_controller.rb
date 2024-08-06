# frozen_string_literal: true

module Api::V1::Machines::Actions
  class HeartbeatsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate!
    before_action :set_machine

    authorize :machine

    def ping
      authorize! with: Machines::HeartbeatPolicy

      if machine.dead?
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

      render jsonapi: machine
    rescue Machine::ResurrectionUnsupportedError,
           Machine::ResurrectionExpiredError
      render_unprocessable_entity detail: 'is dead', code: 'MACHINE_HEARTBEAT_DEAD'
    end

    def reset
      authorize! with: Machines::HeartbeatPolicy

      machine.update!(last_heartbeat_at: nil)

      BroadcastEventService.call(
        event: 'machine.heartbeat.reset',
        account: current_account,
        resource: machine,
      )

      render jsonapi: machine
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
