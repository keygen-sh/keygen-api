# frozen_string_literal: true

class Key < ApplicationRecord
  include Limitable
  include Pageable
  include Searchable

  EXCLUDED_KEYS = %w[actions action].freeze
  SEARCH_ATTRIBUTES = %i[id key].freeze
  SEARCH_RELATIONSHIPS = {
    product: %i[id name],
    policy: %i[id name]
  }.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  belongs_to :account
  belongs_to :policy
  has_one :product, through: :policy

  validates :account, presence: { message: "must exist" }
  validates :policy, presence: { message: "must exist" }

  validates :key, presence: true, allow_blank: false, uniqueness: { case_sensitive: true, scope: :account_id }, exclusion: { in: EXCLUDED_ALIASES, message: "is reserved" }

  validate on: :create do
    errors.add :policy, :not_supported, message: "cannot be added to an unpooled policy" if !policy.nil? && !policy.pool?
  end

  validate on: [:create, :update] do
    errors.add :key, :conflict, message: "must not conflict with another license's identifier (UUID)" if account.licenses.exists? key
    errors.add :key, :conflict, message: "is already being used as a license's key" if account.licenses.exists? key: key
  end

  scope :policy, -> (id) { where policy: id }
  scope :product, -> (id) { joins(:policy).where policies: { product_id: id } }
end
