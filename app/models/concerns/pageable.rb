# frozen_string_literal: true

module Pageable
  SIZE_UPPER = 100
  SIZE_LOWER = 1
  PAGE_LOWER = 1

  # NOTE(ezekg) We're not counting these tables for performance reasons
  WITHOUT_COUNT_MODELS = %w[
    WebhookEvent
    RequestLog
    EventLog
  ]

  extend ActiveSupport::Concern

  included do
    scope :with_pagination, -> (number, size) {
      raise Keygen::Error::InvalidParameterError.new(parameter: "page"), "page number must be a number" unless
        number.respond_to?(:to_i)

      raise Keygen::Error::InvalidParameterError.new(parameter: "page"), "page size must be a number" unless
        size.respond_to?(:to_i)

      number = number.to_i
      size = size.to_i

      if number < PAGE_LOWER
        raise Keygen::Error::InvalidParameterError.new(parameter: "page"), "page number must be a number greater than #{PAGE_LOWER - 1} (got #{number})"
      end

      if size < SIZE_LOWER || size > SIZE_UPPER
        raise Keygen::Error::InvalidParameterError.new(parameter: "page"), "page size must be a number between #{SIZE_LOWER} and #{SIZE_UPPER} (got #{size})"
      end

      # Active record relations store the real model class in klass
      model =
        if self.respond_to?(:klass)
          self.klass
        else
          self.class
        end

      if WITHOUT_COUNT_MODELS.include?(model.name)
        paginate(number).without_count.per(size)
      else
        paginate(number).per(size)
      end
    }
  end
end
