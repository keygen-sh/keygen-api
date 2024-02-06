# frozen_string_literal: true

class ProcessHeartbeatWorker < BaseWorker
  sidekiq_options queue: :critical,
    retry: 1_000_000, # retry forever
    lock: :until_executing,
    on_conflict: {
      client: :replace,
      server: :raise,
    }

  sidekiq_retry_in { |count|
    if count in 0..60
      1.minute.to_i
    else
      10.minutes.to_i
    end
  }

  def perform(process_id)
    process = MachineProcess.find(process_id)

    Keygen.logger.info {
      "[process.heartbeat.worker] account_id=#{process.account.id} process_id=#{process.id}" \
        " process_status=#{process.status} process_interval=#{process.interval}" \
        " process_jid=#{process.heartbeat_jid} jid=#{jid}"
    }

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

    # Clear heartbeat monitor (but only if we're still in possession)
    MachineProcess.where(id: process.id, heartbeat_jid: jid)
                  .limit(1)
                  .update(
                    heartbeat_jid: nil,
                  )
  rescue ActiveRecord::RecordNotFound
    # NOTE(ezekg) Already deactivated
  end

  private

  class ResurrectionPeriodNotPassedError < StandardError
    def backtrace = nil
  end
end
