# frozen_string_literal: true

module AsyncDestroyable
  extend ActiveSupport::Concern

  def destroy_async
    DestroyAsyncJob.perform_later(
      class_name: self.class.name,
      id:,
    )
  end

  class DestroyAsyncJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:default] }

    discard_on ActiveJob::DeserializationError
    retry_on ActiveRecord::ActiveRecordError

    def perform(class_name:, id:)
      klass  = class_name.constantize
      record = klass.find_by(klass.primary_key => id)
      return if
        record.nil?

      record.destroy!
    end
  end
end
