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

  # FIXME(ezekg) Not sure why this isn't already happening by Rails?
  #              We could also do def destroying? = _destroy.
  before_destroy :mark_for_destruction,
    prepend: true

  default_scope -> {
    # FIXME(ezekg) why do we need an explciit table_name everywhere?
    order("#{table_name}.created_at": DEFAULT_SORT_ORDER)
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
end
