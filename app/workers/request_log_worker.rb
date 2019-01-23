class RequestLogWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 10 }
  sidekiq_options queue: :logs

  def perform(account_id, req, res)
    account = Rails.cache.fetch(Account.cache_key(account_id), expires_in: 1.minute) do
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
  rescue Keygen::Error::NotFoundError
    # Skip logging requests for accounts that do not exist
  end
end
