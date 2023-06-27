# frozen_string_literal: true

class CullDeadMachinesWorker < BaseWorker
  sidekiq_options queue: :cron,
                  lock: :until_executed,
                  cronitor_disabled: false

  # In some cases, a machine can be orphaned from its heartbeat worker.
  # For example, when a machine is started with a heartbeat duration
  # of 600, but the policy's heartbeat duration is later changed to
  # 86000, this will cause all in-progress heartbeat monitors to
  # become out of sync if no further pings are sent. After death,
  # this results in a zombie machine that needs to be culled.
  def perform
    machines = Machine.joins(:policy)
                      .where.not(policies: { heartbeat_cull_strategy: 'ALWAYS_REVIVE' })
                      .where(heartbeat_jid: nil)
                      .dead

    machines.find_each do |machine|
      jid = MachineHeartbeatWorker.perform_in(
        rand(60..600).seconds, # fan out to prevent a thundering herd
        machine.id,
      )

      machine.update(heartbeat_jid: jid)
    end
  end
end
