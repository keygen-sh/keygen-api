# frozen_string_literal: true

class MachineHeartbeatWorker < BaseWorker
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

  def perform(machine_id)
    machine = Machine.find(machine_id)
    return unless
      machine.requires_heartbeat?

    if machine.not_started? || machine.dead?
      if machine.last_death_event_sent_at.nil?
        machine.touch(:last_death_event_sent_at)

        # We only want to send this event once per lifecycle (reset on resurrection)
        BroadcastEventService.call(
          event: 'machine.heartbeat.dead',
          account: machine.account,
          resource: machine,
        )
      end

      # Exit early since machine will never be culled
      return if
        machine.policy.always_resurrect_dead?

      # Wait until the machine's resurrection period has passed before deactivating
      raise ResurrectionPeriodNotPassedError if
        machine.policy.resurrect_dead? && !machine.resurrection_period_passed?

      machine.destroy! if
        machine.policy.deactivate_dead?

      return
    end

    BroadcastEventService.call(
      event: 'machine.heartbeat.pong',
      account: machine.account,
      resource: machine,
    )

    # The machine no longer has a heartbeat monitor (until next ping)
    machine.update(
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
