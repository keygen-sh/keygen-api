# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  EXCLUDED_ALIASES = %w[actions action].freeze
  SANITIZE_TSV_RX  = /['?\\:‘’|&!*]/.freeze
  TEST_ENV         = 'test'.freeze

  default_scope -> {
    # FIXME(ezekg) It's easier to test things when sort order to ASC
    case Rails.env
    when TEST_ENV
      order created_at: :asc
    else
      order created_at: :desc
    end
  }

  # This is a preventative measure to assert we never accidentally serialize
  # a model outside of our JSONAPI serializers
  def serializable_hash(...)
    raise NotImplementedError
  end

  def destroy_async
    DestroyModelWorker.perform_async self.class.name, self.id
  end
end
