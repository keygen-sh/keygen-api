# frozen_string_literal: true

module Pageable
  SIZE_UPPER = 100
  SIZE_LOWER = 1
  PAGE_UPPER = 100
  PAGE_LOWER = 1

  # NB(ezekg) we're not counting these tables for performance reasons
  WITHOUT_COUNT_MODELS = %w[
    WebhookEvent
    RequestLog
    EventLog
  ]

  extend ActiveSupport::Concern

  included do
    include KeysetPagination::Model

    # adds UUID validation to the default keyset paginator because pg will raise
    scope :with_keyset_pagination, -> (cursor: nil, size: nil, order: :desc) {
      raise Keygen::Error::InvalidParameterError.new("page cursor must be a valid UUID (got #{cursor.inspect})", parameter: 'page[cursor]') unless
        cursor in UUID_RE | '' | nil

      keyset_paginate(cursor:, size:, order:)
    }

    # TODO(ezekg) deprecate offset pagination and replace with keyset pagination
    scope :with_offset_pagination, -> (number:, size:) {
      raise Keygen::Error::InvalidParameterError.new(parameter: 'page[number]'), 'page number must be a number' unless
        number.respond_to?(:to_i)

      raise Keygen::Error::InvalidParameterError.new(parameter: 'page[size]'), 'page size must be a number' unless
        size.respond_to?(:to_i)

      number = number.to_i
      size   = size.to_i

      if number < PAGE_LOWER || number > PAGE_UPPER
        message = if number > PAGE_UPPER
                    "page number must be a number greater between #{PAGE_LOWER} and #{PAGE_UPPER} (got #{number}, please use cursor-based pagination instead)"
                  else
                    "page number must be a number greater between #{PAGE_LOWER} and #{PAGE_UPPER} (got #{number})"
                  end

        raise Keygen::Error::InvalidParameterError.new(parameter: 'page[number]'), message
      end

      if size < SIZE_LOWER || size > SIZE_UPPER
        raise Keygen::Error::InvalidParameterError.new(parameter: 'page[size]'), "page size must be a number between #{SIZE_LOWER} and #{SIZE_UPPER} (got #{size})"
      end

      paged = offset_paginate(number)

      # NB(ezekg) active record relations store the real model class in klass
      model = if paged.respond_to?(:klass)
                paged.klass
              else
                paged.class
              end

      if WITHOUT_COUNT_MODELS.include?(model.model_name.name)
        paged.without_count.per(size)
      else
        paged.per(size)
      end
    }
  end
end
