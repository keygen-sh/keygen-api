class PruneExpiredTokensWorker < BaseWorker
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT') { '1min' }
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')        { 1_000 }.to_i
  BATCH_WAIT        = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')        { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    tokens = Token.where('expiry is not null and expiry < ?', 90.days.ago)
                  .reorder(created_at: :asc)

    total = tokens.count
    sum   = 0

    batches = (total / BATCH_SIZE) + 1
    batch   = 0

    Keygen.logger.info "[workers.prune-expired-tokens] Starting"
    Keygen.logger.info "[workers.prune-expired-tokens] Pruning #{total} rows: batches=#{batches}"

    loop do
      count = tokens.statement_timeout(STATEMENT_TIMEOUT) do
        tokens.limit(BATCH_SIZE).delete_all
      end

      sum   += count
      batch += 1

      Keygen.logger.info "[workers.prune-expired-tokens] Pruned #{sum}/#{total} rows: batch=#{batch}/#{batches}"

      sleep BATCH_WAIT

      break if count < BATCH_SIZE
    end

    Keygen.logger.info "[workers.prune-expired-tokens] Done"
  end
end
