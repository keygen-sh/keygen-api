# frozen_string_literal: true

class MachineHeartbeatWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 25 }
  sidekiq_options queue: :critical

  def perform(machine_id)
    machine = Machine.find machine_id rescue nil
    return unless machine&.requires_heartbeat?

    if machine.heartbeat_dead?
      BroadcastEventService.call(
        event: "machine.heartbeat.dead",
        account: machine.account,
        resource: machine
      )

      machine.destroy! if machine.policy.deactivate_dead_machines?
    else
      BroadcastEventService.call(
        event: "machine.heartbeat.pong",
        account: machine.account,
        resource: machine
      )
    end
  end
end
