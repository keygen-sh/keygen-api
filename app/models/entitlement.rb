# frozen_string_literal: true

class Entitlement < ApplicationRecord
  include Environmental
  include Limitable
  include Orderable
  include Pageable
  include Diffable

  has_environment

  belongs_to :account
  has_many :license_entitlements, dependent: :delete_all
  has_many :policy_entitlements, dependent: :delete_all
  has_many :release_entitlement_constraints,
    inverse_of: :entitlement,
    dependent: :delete_all
  has_many :event_logs,
    as: :resource

  validates :code, presence: true, allow_blank: false, length: { minimum: 1, maximum: 255 }, uniqueness: { case_sensitive: false, scope: :account_id }
  validates :name, presence: true, allow_blank: false, length: { minimum: 1, maximum: 255 }

  scope :accessible_by, -> accessor {
    case accessor
    in role: { name: 'admin' | 'product' }
      self.all
    in role: { name: 'user' | 'license' }
      self.merge(accessor.entitlements)
    else
      self.none
    end
  }

  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_RE.match?(identifier)

    where('entitlements.id::text ILIKE ?', "%#{identifier}%")
  }

  scope :search_code, -> (term) {
    where('entitlements.code ILIKE ?', "%#{term}%")
  }

  scope :search_name, -> (term) {
    where('entitlements.name ILIKE ?', "%#{term}%")
  }

  ##
  # codes returns the codes of the entitlements.
  def self.codes = reorder(code: :asc).pluck(:code)
end
