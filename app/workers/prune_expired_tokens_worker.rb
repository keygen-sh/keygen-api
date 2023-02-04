class PruneExpiredTokensWorker
  include Sidekiq::Worker

  BATCH_SIZE     = ENV.fetch('PRUNE_BATCH_SIZE')     { 1_000 }.to_i
  SLEEP_DURATION = ENV.fetch('PRUNE_SLEEP_DURATION') { 1 }.to_f

  sidekiq_options queue: :cron, lock: :until_executed

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

      sleep SLEEP_DURATION

      break if count == 0
    end

    Keygen.logger.info "[workers.prune-expired-tokens] Done"
  end
end
