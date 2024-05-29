class PruneReleaseDownloadLinksWorker < BaseWorker
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT') { '1min' }
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')        { 1_000 }.to_i
  BATCH_WAIT        = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')        { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    accounts = Account.joins(:release_download_links)
                      .where('release_download_links.created_at < ?', 90.days.ago)
                      .group('accounts.id')
                      .having('count(release_download_links.id) > 0')

    Keygen.logger.info "[workers.prune-release-download-links] Starting: accounts=#{accounts.count}"

    accounts.find_each do |account|
      account_id = account.id
      batch = 0

      Keygen.logger.info "[workers.prune-release-download-links] Pruning rows: account_id=#{account_id}"

      loop do
        downloads = account.release_download_links
                           .where('created_at < ?', 90.days.ago.beginning_of_day)

        batch += 1
        count = downloads.statement_timeout(STATEMENT_TIMEOUT) do
          downloads.limit(BATCH_SIZE).delete_all
        end

        Keygen.logger.info "[workers.prune-release-download-links] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-release-download-links] Done"
  end
end
