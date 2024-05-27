# frozen_string_literal: true

class CullDeadMachinesWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    machines = Machine.joins(license: :policy)
                      .where.not(policies: { heartbeat_cull_strategy: 'ALWAYS_REVIVE' })
                      .where(heartbeat_jid: nil)
                      .dead

    machines.find_each do |machine|
      jid = MachineHeartbeatWorker.perform_async(machine.id)

      Keygen.logger.info {
        "[machine.heartbeat.cull] account_id=#{machine.account_id} machine_id=#{machine.id}" \
          " machine_status=#{machine.heartbeat_status} machine_interval=#{machine.heartbeat_duration}" \
          " machine_jid=#{jid} machine_jid_was=#{machine.heartbeat_jid}"
      }

      machine.update(heartbeat_jid: jid)
    end
  end
end
