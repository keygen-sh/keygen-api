class PruneReleaseUpgradeLinksWorker < BaseWorker
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT') { '1min' }
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')        { 1_000 }.to_i
  BATCH_WAIT        = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')        { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    accounts = Account.joins(:release_upgrade_links)
                      .where('release_upgrade_links.created_at < ?', 90.days.ago)
                      .group('accounts.id')
                      .having('count(release_upgrade_links.id) > 0')

    Keygen.logger.info "[workers.prune-release-upgrade-links] Starting: accounts=#{accounts.count}"

    accounts.find_each do |account|
      account_id = account.id
      batch = 0

      Keygen.logger.info "[workers.prune-release-upgrade-links] Pruning rows: account_id=#{account_id}"

      loop do
        upgrades = account.release_upgrade_links
                          .where('created_at < ?', 90.days.ago.beginning_of_day)

        batch += 1
        count = upgrades.statement_timeout(STATEMENT_TIMEOUT) do
          upgrades.limit(BATCH_SIZE).delete_all
        end

        Keygen.logger.info "[workers.prune-release-upgrade-links] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-release-upgrade-links] Done"
  end
end
