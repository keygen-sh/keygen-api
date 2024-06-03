class PruneReleaseDownloadLinksWorker < BaseWorker
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT') { '1min' }
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')        { 1_000 }.to_i
  BATCH_WAIT        = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')        { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    target_time = 90.days.ago.beginning_of_day

    accounts = Account.where_assoc_exists(:release_download_links,
      created_at: ...target_time,
    )

    Keygen.logger.info "[workers.prune-release-download-links] Starting: accounts=#{accounts.count} time=#{target_time}"

    accounts.find_each do |account|
      account_id = account.id
      downloads  = account.release_download_links.where('created_at < ?', target_time)

      total = downloads.count
      sum   = 0

      batches = (total / BATCH_SIZE) + 1
      batch   = 0

      Keygen.logger.info "[workers.prune-release-download-links] Pruning #{total} rows: account_id=#{account_id} batches=#{batches}"

      loop do
        count = downloads.statement_timeout(STATEMENT_TIMEOUT) do
          downloads.limit(BATCH_SIZE).delete_all
        end

        sum   += count
        batch += 1

        Keygen.logger.info "[workers.prune-release-download-links] Pruned #{sum}/#{total} rows: account_id=#{account_id} batch=#{batch}/#{batches}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-release-download-links] Done"
  end
end
