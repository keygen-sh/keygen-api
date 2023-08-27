# frozen_string_literal: true

class CullDeadProcessesWorker < BaseWorker
  sidekiq_options queue: :cron,
                  lock: :until_executed,
                  cronitor_disabled: false

  # In some cases, a process can be orphaned from its heartbeat worker.
  # For example, when a process is started with a heartbeat duration
  # of 600, but the policy's heartbeat duration is later changed to
  # 86000, this will cause all in-progress heartbeat monitors to
  # become out of sync if no further pings are sent. After death,
  # this results in a zombie process that needs to be culled.
  def perform
    processes = MachineProcess.joins(:policy)
                              .where.not(policies: { heartbeat_cull_strategy: 'ALWAYS_REVIVE' })
                              .where(heartbeat_jid: nil)
                              .dead

    processes.find_each do |process|
      jid = ProcessHeartbeatWorker.perform_in(
        rand(60..600).seconds, # fan out to prevent a thundering herd
        process.id,
      )

      Keygen.logger.info {
        "[process.heartbeat.cull] account_id=#{process.account.id} process_id=#{process.id}" \
          " process_status=#{process.status} process_interval=#{process.interval}" \
          " process_jid=#{jid} process_jid_was=#{process.heartbeat_jid}"
      }

      process.update(heartbeat_jid: jid)
    end
  end
end
