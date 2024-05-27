# frozen_string_literal: true

class EventNotificationWorker < BaseWorker
  sidekiq_options queue: :logs

  def perform(
    event,
    account_id,
    resource_type,
    resource_id,
    whodunnit_type,
    whodunnit_id,
    idempotency_key
  )
    if (klass = resource_type&.classify&.constantize) && klass.attribute_method?(:account_id)
      resource = klass.find_by(id: resource_id, account_id:)

      resource.notify!(event, idempotency_key: "#{resource_id}:#{idempotency_key}") if
        resource.respond_to?(:notify!)
    end

    # No use in attempting to resend the same idempotent event
    return if
      resource_type == whodunnit_type &&
      resource_id == whodunnit_id

    if (klass = whodunnit_type&.classify&.constantize) && klass.attribute_method?(:account_id)
      whodunnit = klass.find_by(id: whodunnit_id, account_id:)

      whodunnit.notify!(event, idempotency_key: "#{whodunnit_id}:#{idempotency_key}") if
        whodunnit.respond_to?(:notify!)
    end
  end
end
