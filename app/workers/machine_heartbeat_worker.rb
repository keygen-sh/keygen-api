# frozen_string_literal: true

class MachineHeartbeatWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 25 }
  sidekiq_options queue: :critical,
    lock: :until_executing,
    on_conflict: {
      client: :replace,
      server: :raise,
    }

  def perform(machine_id)
    machine = Machine.find(machine_id)
    return unless
      machine.requires_heartbeat?

    if machine.dead?
      BroadcastEventService.call(
        event: 'machine.heartbeat.dead',
        account: machine.account,
        resource: machine,
      )

      machine.destroy! if
        machine.policy.deactivate_dead_machines?

      return
    end

    BroadcastEventService.call(
      event: 'machine.heartbeat.pong',
      account: machine.account,
      resource: machine,
    )
  rescue ActiveRecord::RecordNotFound
    # NOTE(ezekg) Already deactivated
  end
end
