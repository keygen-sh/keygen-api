# frozen_string_literal: true

class RequestLogWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 10 }
  sidekiq_options queue: :logs

  def perform(account_id, req, res)
    @account = Rails.cache.fetch(Account.cache_key(account_id), expires_in: 15.minutes) do
      Account.find account_id
    end

    account.request_logs.create!(
      requestor_type: req['requestor_type'],
      requestor_id: req['requestor_id'],

      resource_type: req['resource_type'],
      resource_id: req['resource_id'],

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
  rescue Keygen::Error::NotFoundError
    # Skip logging requests for accounts that do not exist
  end

  private

  attr_reader :account
end
