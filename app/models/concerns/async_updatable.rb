# frozen_string_literal: true

module AsyncUpdatable
  extend ActiveSupport::Concern

  def update_async(**attributes)
    changed_attributes = changes.transform_values(&:last)
                                .merge(attributes)

    UpdateAsyncJob.perform_later(
      class_name: self.class.name,
      id:,
      attributes: changed_attributes,
    )
  end

  # optimistic variant: assigns attributes, validates, and marks record as readonly
  def update_async!(**attributes)
    assign_attributes(updated_at: Time.current, **attributes)
    validate!
    readonly!

    # enqueue after we assign/validate
    update_async

    self
  end

  class UpdateAsyncJob < ActiveJob::Base
    self.log_arguments = Rails.env.local?

    queue_as { ActiveRecord.queues[:default] }

    discard_on ActiveJob::DeserializationError
    retry_on ActiveRecord::ActiveRecordError

    def perform(class_name:, id:, attributes:)
      klass  = class_name.constantize
      record = klass.find_by(klass.primary_key => id)
      return if
        record.nil?

      record.update!(attributes)
    end
  end
end
