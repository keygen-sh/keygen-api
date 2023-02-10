# frozen_string_literal: true

class ProcessHeartbeatWorker < BaseWorker
  sidekiq_retry_in { 1.minute.to_i }
  sidekiq_options queue: :critical,
    retry: Float::INFINITY, # retry forever
    lock: :until_executing,
    on_conflict: {
      client: :replace,
      server: :raise,
    }

  def perform(process_id)
    process = MachineProcess.find(process_id)

    if process.dead?
      if process.last_death_event_sent_at.nil?
        process.touch(:last_death_event_sent_at)

        # We only want to send this event once per lifecycle (reset on resurrection)
        BroadcastEventService.call(
          event: 'process.heartbeat.dead',
          account: process.account,
          resource: process,
        )
      end

      # Exit early since process will never be culled
      return if
        process.policy.always_resurrect_dead?

      # Wait until the process's resurrection period has passed before deactivating
      raise ResurrectionPeriodNotPassedError if
        process.policy.resurrect_dead? && !process.resurrection_period_passed?

      process.destroy! if
        process.policy.deactivate_dead?

      return
    end

    BroadcastEventService.call(
      event: 'process.heartbeat.pong',
      account: process.account,
      resource: process,
    )
  rescue ActiveRecord::RecordNotFound
    # NOTE(ezekg) Already deactivated
  end

  private

  class ResurrectionPeriodNotPassedError < StandardError
    def backtrace
      nil
    end
  end
end
