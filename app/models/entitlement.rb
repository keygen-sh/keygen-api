# frozen_string_literal: true

class Entitlement < ApplicationRecord
  include Limitable
  include Pageable
  include Searchable
  include Diffable

  SEARCH_ATTRIBUTES    = %i[id name code].freeze
  SEARCH_RELATIONSHIPS = {}.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  belongs_to :account
  has_many :license_entitlements, dependent: :delete_all
  has_many :policy_entitlements, dependent: :delete_all
  has_many :release_entitlement_constraints,
    inverse_of: :entitlement,
    dependent: :delete_all
  has_many :event_logs,
    as: :resource

  validates :account, presence: { message: 'must exist' }

  validates :code, presence: true, allow_blank: false, length: { minimum: 1, maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }
  validates :name, presence: true, allow_blank: false, length: { minimum: 1, maximum: 255 }
end
