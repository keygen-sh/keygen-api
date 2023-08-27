# frozen_string_literal: true

module Api::V1::MachineProcesses::Actions
  class HeartbeatsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_machine_process

    authorize :machine_process

    def ping
      authorize! with: MachineProcesses::HeartbeatPolicy

      if machine_process.dead?
        machine_process.resurrect!

        BroadcastEventService.call(
          event: 'process.heartbeat.resurrected',
          account: current_account,
          resource: machine_process,
        )
      else
        machine_process.ping!

        BroadcastEventService.call(
          event: 'process.heartbeat.ping',
          account: current_account,
          resource: machine_process,
        )
      end

      # Queue up heartbeat worker which will handle deactivating dead processes
      jid = ProcessHeartbeatWorker.perform_in(
        machine_process.interval + MachineProcess::HEARTBEAT_DRIFT,
        machine_process.id,
      )

      machine_process.update(
        heartbeat_jid: jid,
      )

      Keygen.logger.info {
        "[process.heartbeat.ping] account_id=#{current_account.id} process_id=#{machine_process.id}" \
          " process_status=#{machine_process.status} process_interval=#{machine_process.interval}" \
          " process_jid=#{jid} process_jid_was=#{machine_process.heartbeat_jid_previously_was}"
      }

      render jsonapi: machine_process
    rescue MachineProcess::ResurrectionUnsupportedError,
           MachineProcess::ResurrectionExpiredError
      render_unprocessable_entity detail: 'is dead', code: 'PROCESS_HEARTBEAT_DEAD'
    end

    private

    attr_reader :machine_process

    def set_machine_process
      scoped_machine_processes = authorized_scope(current_account.machine_processes)

      @machine_process = scoped_machine_processes.find(params[:id])

      Current.resource = machine_process
    end
  end
end
