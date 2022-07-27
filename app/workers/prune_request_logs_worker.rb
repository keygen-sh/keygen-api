class PruneRequestLogsWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  BATCH_SIZE     = ENV.fetch('PRUNE_BATCH_SIZE')     { 1_000 }.to_i
  SLEEP_DURATION = ENV.fetch('PRUNE_SLEEP_DURATION') { 1 }.to_f

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    accounts = Account.joins(:request_logs)
                      .where('request_logs.created_at < ?', 30.days.ago)
                      .group('accounts.id')
                      .having('count(request_logs.id) > 0')

    Keygen.logger.info "[workers.prune-request-logs] Starting: accounts=#{accounts.count}"

    accounts.find_each do |account|
      account_id = account.id
      batch = 0

      Keygen.logger.info "[workers.prune-request-logs] Pruning rows: account_id=#{account_id}"

      loop do
        logs = account.request_logs
                      .where('created_at < ?', 30.days.ago.beginning_of_day)

        batch += 1
        count = logs.limit(BATCH_SIZE)
                    .delete_all

        Keygen.logger.info "[workers.prune-request-logs] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        sleep SLEEP_DURATION

        break if count == 0
      end
    end

    Keygen.logger.info "[workers.prune-request-logs] Done"
  end
end
