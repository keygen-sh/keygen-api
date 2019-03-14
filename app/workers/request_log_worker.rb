class RequestLogWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 10 }
  sidekiq_options queue: :logs

  def perform(account_id, req, res)
    @account = Rails.cache.fetch(Account.cache_key(account_id), expires_in: 1.minute) do
      Account.find account_id
    end

    account.request_logs.create(
      request_id: req['request_id'],
      url: req['url'],
      method: req['method'],
      ip: req['ip'],
      user_agent: req['user_agent'],
      status: res['status']
    )

    increment_daily_request_count!
  rescue Keygen::Error::NotFoundError
    # Skip logging requests for accounts that do not exist
  end

  private

  attr_reader :account

  def increment_daily_request_count!
    # FIXME(ezekg) Workaround for Rails 5 not supporting :expires_in for cache#increment
    if !cache.exist?(account.daily_request_count_cache_key, raw: true)
      cache.write account.daily_request_count_cache_key, 1, raw: true, expires_in: 1.day
    else
      cache.increment account.daily_request_count_cache_key
    end
  rescue => e
    Raygun.track_exception e
  end

  def cache
    Rails.cache
  end
end
