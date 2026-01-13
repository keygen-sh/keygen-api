# frozen_string_literal: true

module AsyncTouchable
  extend ActiveSupport::Concern

  def touch_async(*names, time: nil)
    TouchAsyncJob.perform_later(
      class_name: self.class.name,
      id:,
      names:,
      time:,
    )
  end

  # optimistic variant: assigns timestamps, validates, and marks record as readonly
  def touch_async!(*names, time: Time.current)
    raise ArgumentError, 'time cannot be nil' if time.nil?

    [:updated_at, *names].each { self[it] = time }
    validate!
    readonly!

    # enqueue after we assign/validate
    touch_async(*names, time:)

    self
  end

  class TouchAsyncJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:default] }

    discard_on ActiveJob::DeserializationError
    retry_on ActiveRecord::ActiveRecordError

    def perform(class_name:, id:, names:, time:)
      klass  = class_name.constantize
      record = klass.find_by(klass.primary_key => id)
      return if
        record.nil?

      record.touch(*names, time:)
    end
  end
end
