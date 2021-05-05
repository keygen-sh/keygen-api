class PruneExpiredTokensWorker
  include Sidekiq::Worker
  include Sidekiq::Cronitor

  sidekiq_options queue: :cron, lock: :until_executed

  def perform
    loop do
      tokens = Token.where('expiry is not null and expiry < ?', 90.days.ago)
                    .reorder(created_at: :asc)

      count = tokens.limit(10_000)
                    .delete_all

      break if count == 0
    end
  end
end