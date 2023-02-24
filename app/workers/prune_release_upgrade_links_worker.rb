class PruneReleaseUpgradeLinksWorker < BaseWorker
  BATCH_SIZE     = ENV.fetch('PRUNE_BATCH_SIZE')     { 1_000 }.to_i
  SLEEP_DURATION = ENV.fetch('PRUNE_SLEEP_DURATION') { 1 }.to_f

  sidekiq_options queue: :cron,
                  lock: :until_executed,
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
        count = upgrades.limit(BATCH_SIZE)
                        .delete_all

        Keygen.logger.info "[workers.prune-release-upgrade-links] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep SLEEP_DURATION

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-release-upgrade-links] Done"
  end
end
