class PruneEventLogsWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  HIGH_VOLUME_EVENTS = %w[
    license.validation.succeeded
    license.validation.failed
    machine.heartbeat.ping
    machine.heartbeat.pong
    process.heartbeat.ping
    process.heartbeat.pong
  ]

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    accounts = Account.joins(:event_logs)
                      .where('event_logs.created_at < ?', 90.days.ago)
                      .group('accounts.id')
                      .having('count(event_logs.id) > 0')

    Keygen.logger.info "[workers.prune-event-logs] Starting: accounts=#{accounts.count}"

    # We only want to prune certain high-volume event logs
    event_ids = Event.where(event: HIGH_VOLUME_EVENTS)
                     .pluck(:id)

    accounts.find_each do |account|
      account_id = account.id
      batch      = 0

      Keygen.logger.info "[workers.prune-event-logs] Pruning rows: account_id=#{account_id}"

      loop do
        event_logs = account.event_logs
                            .where('created_at < ?', 90.days.ago.beginning_of_day)
                            .where(event: event_ids)

        batch += 1
        count = event_logs.limit(1_000)
                          .delete_all

        Keygen.logger.info "[workers.prune-event-logs] Pruned #{count} rows: account_id=#{account_id} batch=#{batch}"

        break if count == 0
      end
    end

    Keygen.logger.info "[workers.prune-event-logs] Done"
  end
end
