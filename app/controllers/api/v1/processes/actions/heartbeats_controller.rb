# frozen_string_literal: true

module Api::V1::Processes::Actions
  class HeartbeatsController < Api::V1::BaseController
    before_action :scope_to_current_account!
    before_action :require_active_subscription!
    before_action :authenticate_with_token!
    before_action :set_process

    def ping
      authorize @process

      if @process.dead?
        return render_unprocessable_entity(detail: 'is dead', code: 'PROCESS_HEARTBEAT_DEAD', source: { pointer: '/data/attributes/status' }) unless
          @process.resurrect_dead? && !@process.resurrection_period_passed?

        @process.resurrect!

        BroadcastEventService.call(
          event: 'process.heartbeat.resurrected',
          account: current_account,
          resource: @process,
        )
      else
        @process.ping!

        BroadcastEventService.call(
          event: 'process.heartbeat.ping',
          account: current_account,
          resource: @process,
        )
      end

      # Queue up heartbeat worker which will handle deactivating dead processes
      ProcessHeartbeatWorker.perform_in(
        @process.interval + MachineProcess::HEARTBEAT_DRIFT,
        @process.id,
      )

      render jsonapi: @process
    end

    private

    def set_process
      scoped_processes = policy_scope(current_account.machine_processes)

      # FIXME(ezekg) We're using an instance variable here instead of an
      #              attr_reader because Rails has an internal process
      #              method that conflicts.
      @process = scoped_processes.find(params[:id])

      Current.resource = @process
    end
  end
end
