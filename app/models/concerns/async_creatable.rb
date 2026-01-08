# frozen_string_literal: true

module AsyncCreatable
  extend ActiveSupport::Concern

  class_methods do
    def create_async(attributes)
      optimistic = new(attributes).tap(&:readonly!)

      CreateAsyncJob.perform_later(
        class_name: name,
        attributes:,
      )

      optimistic
    end
  end

  class CreateAsyncJob < ActiveJob::Base
    queue_as { ActiveRecord.queues[:default] }

    discard_on ActiveJob::DeserializationError

    def perform(class_name:, attributes:)
      klass = class_name.constantize

      klass.create!(attributes)
    end
  end
end
