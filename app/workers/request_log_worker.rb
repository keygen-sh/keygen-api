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

    # Inserting with a transaction to ensure all data is recorded
    account.request_logs.transaction do
      rows = account.request_logs.insert!(
        {
          id: request_id,
          requestor_type: requestor_type,
          requestor_id: requestor_id,
          resource_type: resource_type,
          resource_id: resource_id,
          created_date: request_time,
          created_at: request_time,
          updated_at: Time.current,
          user_agent: request_user_agent,
          method: request_method,
          url: request_url,
          ip: request_ip,
          status: response_status,
        },
        returning: :id,
      )

      # Insert blobs in the same transaction
      log_id = rows.to_a.first['id']

      account.request_log_blobs.insert_all!([
        { blob_type: :request_body,       blob: request_body,       request_log_id: log_id },
        { blob_type: :response_signature, blob: response_signature, request_log_id: log_id },
        { blob_type: :response_body,      blob: response_body,      request_log_id: log_id },
      ])
    end
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
