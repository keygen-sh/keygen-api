# frozen_string_literal: true

class RecordMetricWorker < BaseWorker
  sidekiq_options queue: :metrics

  def perform(event, account_id, resource_type, resource_id)
    event_type = Rails.cache.fetch(EventType.cache_key(event), skip_nil: true, expires_in: 1.day) do
      EventType.find_or_create_by! event: event
    end
    account = Rails.cache.fetch(Account.cache_key(account_id), skip_nil: true, expires_in: 15.minutes) do
      Account.find account_id
    end

    # Skip metric recording for non-existent accounts
    return if
      account.nil?

    # Skip metric recording for non-owned models
    klass = resource_type.classify.constantize

    return unless
      klass.attribute_method?(:account_id)

    resource = if klass.present?
                 klass.find_by(account_id: account.id, id: resource_id)
               else
                 nil
               end

    recorded_at = Time.current
    data =
      if resource.present?
        { resource: resource.id }.tap { |data|
          %w[product policy license user bearer].map(&:to_sym).each do |rel|
            data[rel] = resource.send("#{rel}_id") if resource.respond_to?("#{rel}_id")
          end
        }.compact
      else
        { resource: resource_id }
      end

    account.metrics.insert!({
      id: UUID7.generate,
      event_type_id: event_type.id,
      created_date: recorded_at,
      created_at: recorded_at,
      updated_at: recorded_at,
      data: data,
    })
  end
end
