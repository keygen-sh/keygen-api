# frozen_string_literal: true

class CullDeadProcessesWorker < BaseWorker
  sidekiq_options queue: :cron,
                  lock: :until_executed, lock_ttl: 10.minutes, on_conflict: :raise,
                  cronitor_disabled: false

  def perform
    processes = MachineProcess.joins(:policy)
                              .where.not(policies: { heartbeat_cull_strategy: 'ALWAYS_REVIVE' })
                              .where(heartbeat_jid: nil)
                              .dead

    processes.find_each do |process|
      jid = ProcessHeartbeatWorker.perform_async(process.id)

      Keygen.logger.info {
        "[process.heartbeat.cull] account_id=#{process.account.id} process_id=#{process.id}" \
          " process_status=#{process.status} process_interval=#{process.interval}" \
          " process_jid=#{jid} process_jid_was=#{process.heartbeat_jid}"
      }

      process.update(heartbeat_jid: jid)
    end
  end
end
