# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true

  # FIXME(ezekg) More intuitive to test things in ASC order
  DEFAULT_SORT_ORDER = if Rails.env.test?
                         :asc
                       else
                         :desc
                       end

  EXCLUDED_ALIASES = %w[actions action].freeze
  SANITIZE_TSV_RE  = /['?\\:‘’|&!*]/.freeze

  default_scope -> {
    order(created_at: DEFAULT_SORT_ORDER)
  }

  scope :without_order, -> {
    reorder(nil)
  }

  scope :without_limit, -> {
    limit(nil)
  }

  # sample returns a random record for the model.
  def self.sample = find_by(id: ids.sample) unless Rails.env.production?

  # This is a preventative measure to assert we never accidentally serialize
  # a model outside of our JSONAPI serializers
  def serializable_hash(...)
    raise NotImplementedError
  end

  def destroy_async
    DestroyModelWorker.perform_async self.class.name, self.id
  end
end
