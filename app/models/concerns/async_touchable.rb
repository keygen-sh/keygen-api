# frozen_string_literal: true

module AsyncTouchable
  extend ActiveSupport::Concern

  def touch_async(*names, time: nil)
    TouchAsyncJob.perform_later(
      class_name: self.class.name,
      id:,
      names:,
      time:,
      last_updated_at: updated_at,
    )
  end

  # optimistic variant: assigns timestamps, validates, and marks record as readonly
  def touch_async!(*names, time: nil)
    time ||= Time.current # if not provided we have to default to now

    touch_async(*names, time:)

    [:updated_at, *names].each { self[it] = time }
    validate!
    readonly!

    self
  end

  class TouchAsyncJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:default] }

    discard_on ActiveJob::DeserializationError

    def perform(class_name:, id:, names:, time:, last_updated_at:)
      klass  = class_name.constantize
      record = klass.find_by(klass.primary_key => id)
      return if
        record.nil?

      # discard stale touches
      return if
        record.updated_at > last_updated_at

      record.touch(*names, time:)
    end
  end
end
