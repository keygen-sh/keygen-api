# frozen_string_literal: true

class RecordMetricWorker
  include Sidekiq::Worker
  include Sidekiq::Throttled::Worker

  sidekiq_throttle concurrency: { limit: 10 }
  sidekiq_options queue: :metrics

  def perform(event, account_id, resource_type, resource_id)
    event_type = Rails.cache.fetch(EventType.cache_key(event), skip_nil: true, expires_in: 1.day) do
      EventType.find_or_create_by! event: event
    end
    account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
      Account.find account_id
    end

    # Skip metric recording for non-existent accounts
    return if account.nil?

    # TODO(ezekg) Should probably scope this to the account
    resource = resource_type.classify.constantize.find_by id: resource_id
    recorded_at = Time.current
    data =
      if resource.present?
        { resource: resource.id }.tap { |data|
          %w[product policy license user bearer].map(&:to_sym).each do |r|
            data[r] = resource.send(r)&.id if resource.respond_to? r
          end
        }.compact
      else
        { resource: resource_id }
      end

    account.metrics.insert!(
      event_type_id: event_type.id,
      created_at: recorded_at,
      updated_at: recorded_at,
      data: data
    )
  end
end
