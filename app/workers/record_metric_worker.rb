class RecordMetricWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 10 }
  sidekiq_options queue: :metrics

  def perform(metric, account_id, resource_type, resource_id)
    account = Account.find account_id

    # TODO(ezekg) Should probably scope this to the account
    resource = resource_type.classify.constantize.find_by id: resource_id
    data =
      if resource.present?
        { resource: resource.id }.tap { |data|
          %w[product policy license user].map(&:to_sym).each do |r|
            data[r] = resource.send(r)&.id if resource.respond_to? r
          end
        }.compact
      else
        { resource: resource_id }
      end

    account.metrics.create(
      metric: metric,
      data: data
    )
  end
end
