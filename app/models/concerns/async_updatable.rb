# frozen_string_literal: true

module AsyncUpdatable
  extend ActiveSupport::Concern

  def update_async(attributes)
    UpdateAsyncJob.perform_later(
      class_name: self.class.name,
      id:,
      attributes:,
      last_updated_at: updated_at,
    )
  end

  class UpdateAsyncJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:default] }

    discard_on ActiveJob::DeserializationError

    def perform(class_name:, id:, attributes:, last_updated_at:)
      klass  = class_name.constantize
      record = klass.find_by(klass.primary_key => id)
      return if
        record.nil?

      # discard stale updates: if the record has been modified since this job
      # was enqueued, a more recent update has already occurred.
      return if
        record.updated_at > last_updated_at

      record.update!(attributes)
    end
  end
end
