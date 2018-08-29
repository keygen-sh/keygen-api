class MetricWorker
  include Sidekiq::Worker

  sidekiq_throttle concurrency: { limit: 10 )
  sidekiq_options queue: :metrics

  def perform(metric, account_id, data)
    account = Account.find_by id: account_id
    return if account.nil?

    account.metrics.create(
      metric: metric,
      data: JSON.parse(data)
    )
  rescue JSON::ParserError
    false
  end
end
