# frozen_string_literal: true

class RequestLogWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 10 }
  sidekiq_options queue: :logs

  def perform(account_id, req, res)
    account = fetch_account(account_id)

    # Skip request logs for non-existent accounts
    return if
      account.nil?

    account.request_logs.insert!(
      id: req['request_id'],

      requestor_type: req['requestor_type'],
      requestor_id: req['requestor_id'],

      resource_type: req['resource_type'],
      resource_id: req['resource_id'],

      created_at: req['request_time'],
      updated_at: req['request_time'],

      request_id: req['request_id'],
      request_body: req['body'],

      response_signature: res['signature'],
      response_body: res['body'],

      url: req['url'],
      method: req['method'],
      ip: req['ip'],
      user_agent: req['user_agent'],
      status: res['status']
    )
  rescue PG::UniqueViolation
    # NOTE(ezekg) Don't log duplicates
  end

  private

  def fetch_account(account_id)
    cache_key = Account.cache_key(account_id)

    Rails.cache.fetch(cache_key, skip_nil: true, expires_in: 15.minutes) do
      FindByAliasService.call(scope: Account, identifier: account_id, aliases: :slug)
    end
  rescue Keygen::Error::NotFoundError
    nil
  end
end
