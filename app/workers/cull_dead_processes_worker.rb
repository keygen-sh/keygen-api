# frozen_string_literal: true

class CullDeadProcessesWorker < BaseWorker
  sidekiq_options queue: :cron,
                  cronitor_enabled: true

  def perform
    processes = MachineProcess.joins(:policy)
                              .where.not(policies: { heartbeat_cull_strategy: 'ALWAYS_REVIVE' })
                              .where(heartbeat_jid: nil)
                              .dead

    processes.unordered.find_each do |process|
      jid = SecureRandom.hex(12) # precalc jid so we can set it on process beforehand
      job = ProcessHeartbeatWorker.set(jid:)

      Keygen.logger.info {
        "[process.heartbeat.cull] account_id=#{process.account.id} process_id=#{process.id}" \
          " process_status=#{process.status} process_interval=#{process.interval}" \
          " process_jid=#{jid} process_jid_was=#{process.heartbeat_jid}"
      }

      unless process.update(heartbeat_jid: jid)
        Keygen.logger.warn { "[process.heartbeat.cull] failed to attach: process_id=#{process.id} jid=#{jid}" }
      end

      unless job.perform_async(process.id)
        Keygen.logger.warn { "[process.heartbeat.cull] failed to queue: process_id=#{process.id} jid=#{jid}" }
      end
    end
  end
end
