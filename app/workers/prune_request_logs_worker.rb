class PruneRequestLogsWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    accounts = Account.joins(:request_logs)
                      .where('request_logs.created_at < ?', 30.days.ago)
                      .group('accounts.id')
                      .having('count(request_logs.id) > 0')

    Keygen.logger.info "[worker.prune-request-logs] Starting: accounts=#{accounts.count}"

    accounts.find_each do |account|
      account_id = account.id
      batch = 0

      Keygen.logger.info "[worker.prune-request-logs] Pruning rows: account_id=#{account_id}"

      loop do
        logs = account.request_logs
                      .where('created_at < ?', 30.days.ago.beginning_of_day)

        batch += 1
        count = logs.limit(1_000)
                    .delete_all

        Keygen.logger.info "[worker.prune-request-logs] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        break if count == 0
      end
    end

    Keygen.logger.info "[worker.prune-request-logs] Done"
  end
end