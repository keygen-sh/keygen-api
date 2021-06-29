class PruneReleaseDownloadLinksWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options queue: :cron, lock: :until_executed

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
        count = downloads.limit(1_000)
                         .delete_all

        Keygen.logger.info "[workers.prune-release-download-links] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        break if count == 0
      end
    end

    Keygen.logger.info "[workers.prune-release-download-links] Done"
  end
end
