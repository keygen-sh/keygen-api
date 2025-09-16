# frozen_string_literal: true

class Entitlement < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable
  include Diffable

  has_many :license_entitlements, dependent: :delete_all
  has_many :policy_entitlements, dependent: :delete_all
  has_many :release_entitlement_constraints,
    inverse_of: :entitlement,
    dependent: :delete_all
  has_many :event_logs,
    as: :resource

  has_environment
  has_account

  validates :code,
    exclusion: { in: EXCLUDED_ALIASES, message: 'is reserved' },
    uniqueness: { case_sensitive: false, scope: :account_id },
    length: { minimum: 1, maximum: 255 },
    format: { without: UUID_RE },
    allow_blank: false,
    presence: true

  validates :name,
    length: { minimum: 1, maximum: 255 },
    allow_blank: false,
    presence: true

  validates :metadata,
    json: {
      maximum_bytesize: 16.kilobytes,
      maximum_depth: 4,
      maximum_keys: 64,
    }

  scope :accessible_by, -> accessor {
    case accessor
    in role: Role(:admin | :product)
      all
    in role: Role(:environment)
      for_environment(accessor)
    in role: Role(:user | :license)
      merge(accessor.entitlements)
    else
      none
    end
  }

  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_RE.match?(identifier)

    where('entitlements.id::text ILIKE ?', "%#{sanitize_sql_like(identifier)}%")
  }

  scope :search_code, -> (term) {
    return none if
      term.blank?

    where('entitlements.code ILIKE ?', "%#{sanitize_sql_like(term)}%")
  }

  scope :search_name, -> (term) {
    return none if
      term.blank?

    where('entitlements.name ILIKE ?', "%#{sanitize_sql_like(term)}%")
  }

  ##
  # codes returns the codes of the entitlements.
  def self.codes = reorder(code: :asc).pluck(:code)
end
