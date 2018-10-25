class RecordMetricWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 10 }
  sidekiq_options queue: :metrics

  def perform(metric, account_id, resource_type, resource_id)
    account = Account.find account_id
    resource = resource_type.classify.constantize.find resource_id

    account.metrics.create(
      metric: metric,
      data: { resource: resource.id }.tap { |data|
        %w[product policy license user].map(&:to_sym).each do |r|
          data[r] = resource.send(r)&.id if resource.respond_to? r
        end
      }.compact
    )
  end
end
