class PruneWebhookEventsWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    accounts = Account.joins(:webhook_events)
                      .where('webhook_events.created_at < ?', 30.days.ago)
                      .group('accounts.id')
                      .having('count(webhook_events.id) > 0')

    accounts.find_each do |account|
      loop do
        events = account.webhook_events
                        .where('created_at < ?', 30.days.ago.beginning_of_day)

        count = events.limit(1_000)
                      .delete_all

        break if count == 0
      end
    end
  end
end