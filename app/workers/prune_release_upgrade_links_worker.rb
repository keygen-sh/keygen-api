class PruneReleaseUpgradeLinksWorker < BaseWorker
  STATEMENT_TIMEOUT = ENV.fetch('KEYGEN_PRUNE_STATEMENT_TIMEOUT') { '1min' }
  BATCH_SIZE        = ENV.fetch('KEYGEN_PRUNE_BATCH_SIZE')        { 1_000 }.to_i
  BATCH_WAIT        = ENV.fetch('KEYGEN_PRUNE_BATCH_WAIT')        { 1 }.to_f

  sidekiq_options queue: :cron,
                  cronitor_disabled: false

  def perform
    cutoff_time = 90.days.ago.beginning_of_day

    accounts = Account.where_assoc_exists(:release_upgrade_links,
      created_at: ...cutoff_time,
    )

    Keygen.logger.info "[workers.prune-release-upgrade-links] Starting: accounts=#{accounts.count} time=#{cutoff_time}"

    accounts.unordered.find_each do |account|
      account_id = account.id
      upgrades   = account.release_upgrade_links.where('created_at < ?', cutoff_time)
                                                .reorder(created_at: :asc)

      total = upgrades.count
      sum   = 0

      batches = (total / BATCH_SIZE) + 1
      batch   = 0

      Keygen.logger.info "[workers.prune-release-upgrade-links] Pruning #{total} rows: account_id=#{account_id} batches=#{batches}"

      loop do
        count = upgrades.statement_timeout(STATEMENT_TIMEOUT) do
          upgrades.limit(BATCH_SIZE).delete_all
        end

        sum   += count
        batch += 1

        Keygen.logger.info "[workers.prune-release-upgrade-links] Pruned #{sum}/#{total} rows: account_id=#{account_id} batch=#{batch}/#{batches}"

        sleep BATCH_WAIT

        break if count < BATCH_SIZE
      end
    end

    Keygen.logger.info "[workers.prune-release-upgrade-links] Done"
  end
end
