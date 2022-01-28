# frozen_string_literal: true

class RequestLogWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 10 }
  sidekiq_options queue: :logs

  def perform(
    account_id,
    requestor_type,
    requestor_id,
    resource_type,
    resource_id,
    request_id,
    request_time,
    request_user_agent,
    request_method,
    request_url,
    request_body,
    request_ip,
    response_signature,
    response_body,
    response_status
  )
    account = fetch_account(account_id)

    # Skip request logs for non-existent accounts
    return if
      account.nil?

    account.request_logs.insert!(
      id: request_id,
      requestor_type: requestor_type,
      requestor_id: requestor_id,
      resource_type: resource_type,
      resource_id: resource_id,
      created_at: request_time,
      updated_at: Time.current,
      user_agent: request_user_agent,
      method: request_method,
      url: request_url,
      request_body: request_body,
      ip: request_ip,
      response_signature: response_signature,
      response_body: response_body,
      status: response_status,
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

# FIXME(ezekg) From Sidekiq 6.4 migration. Remove once all
#              RequestLogWorker2 workers are cleared.
RequestLogWorker2 = RequestLogWorker
