class PruneExpiredTokensWorker < BaseWorker
  BATCH_SIZE = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE') { 1_000 }.to_i
  BATCH_WAIT = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT') { 1 }.to_f

  sidekiq_options queue: :cron,
                  lock: :until_executed,
                  cronitor_disabled: false

  def perform
    batch = 0

    Keygen.logger.info "[workers.prune-expired-tokens] Starting"

    loop do
      tokens = Token.where('expiry is not null and expiry < ?', 90.days.ago)
                    .reorder(created_at: :asc)

      batch += 1
      count = tokens.limit(BATCH_SIZE)
                    .delete_all

      Keygen.logger.info "[workers.prune-expired-tokens] Pruned #{count} rows: batch=#{batch}"

      sleep BATCH_WAIT

      break if count < BATCH_SIZE
    end

    Keygen.logger.info "[workers.prune-expired-tokens] Done"
  end
end
