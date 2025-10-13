# frozen_string_literal: true

# FIXME(ezekg) remove after migrating to new bulk worker and queue drains
class RequestLogWorker < BaseWorker
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
    response_status,
    environment_id,
    request_headers = nil,
    response_headers = nil,
    request_run_time = nil,
    request_queue_time = nil
  )
    return unless
      Keygen.ee? && Keygen.ee { it.entitled?(:request_logs) }

    account = fetch_account(account_id)

    # Skip request logs for non-existent accounts
    return if
      account.nil?

    account.request_logs.insert!({
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
      request_headers:,
      request_body: request_body,
      ip: request_ip,
      response_signature: response_signature,
      response_headers:,
      response_body: response_body,
      status: response_status,
      environment_id:,
      run_time: request_run_time,
      queue_time: request_queue_time,
    })
  rescue PG::UniqueViolation
    # NOTE(ezekg) Don't log duplicates
  end

  private

  def fetch_account(account_id)
    cache_key = Account.cache_key(account_id)

    Rails.cache.fetch(cache_key, skip_nil: true, expires_in: 15.minutes) do
      FindByAliasService.call(Account, id: account_id, aliases: :slug)
    end
  rescue Keygen::Error::NotFoundError
    nil
  end
end
