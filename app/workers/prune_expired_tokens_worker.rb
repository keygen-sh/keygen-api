class PruneExpiredTokensWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    batch = 0

    Keygen.logger.info "[worker.prune-expired-tokens] Starting"

    loop do
      tokens = Token.where('expiry is not null and expiry < ?', 90.days.ago)
                    .reorder(created_at: :asc)

      batch += 1
      count = tokens.limit(10_000)
                    .delete_all

      Keygen.logger.info "[worker.prune-expired-tokens] Pruned #{count} rows: batch=##{batch}"

      break if count == 0
    end

    Keygen.logger.info "[worker.prune-expired-tokens] Done"
  end
end