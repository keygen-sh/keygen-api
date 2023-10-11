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
  #
  # Another scenario is where a policy is created that does not require
  # heartbeats, but is later updated to require heartbeats. Without
  # this worker, previously created machines in an idle state would
  # stick around even though they're required to have a heartbeat.
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

      Keygen.logger.info {
        "[machine.heartbeat.cull] account_id=#{machine.account_id} machine_id=#{machine.id}" \
          " machine_status=#{machine.heartbeat_status} machine_interval=#{machine.heartbeat_duration}" \
          " machine_jid=#{jid} machine_jid_was=#{machine.heartbeat_jid}"
      }

      machine.update(heartbeat_jid: jid)
    end
  end
end
