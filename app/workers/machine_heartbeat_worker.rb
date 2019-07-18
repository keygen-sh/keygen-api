# frozen_string_literal: true

class MachineHeartbeatWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 25 }
  sidekiq_options queue: :system

  def perform(machine_id)
    machine = Machine.find machine_id rescue nil
    return unless machine&.requires_heartbeat?

    if machine.heartbeat_dead?
      CreateWebhookEventService.new(
        event: "machine.heartbeat.dead",
        account: machine.account,
        resource: machine
      ).execute

      machine.destroy if machine.policy.deactivate_dead_machines?
    else
      CreateWebhookEventService.new(
        event: "machine.heartbeat.pong",
        account: machine.account,
        resource: machine
      ).execute
    end
  end
end