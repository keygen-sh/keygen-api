# frozen_string_literal: true

class Entitlement < ApplicationRecord
  include Limitable
  include Pageable
  include Diffable

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

  # Give products the ability to read all entitlements
  scope :for_product, -> id { self }

  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_REGEX.match?(identifier)

    where('entitlements.id::text ILIKE ?', "%#{identifier}%")
  }

  scope :search_code, -> (term) {
    where('entitlements.code ILIKE ?', "%#{term}%")
  }

  scope :search_name, -> (term) {
    where('entitlements.name ILIKE ?', "%#{term}%")
  }
end
