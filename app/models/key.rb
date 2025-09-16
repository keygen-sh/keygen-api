# frozen_string_literal: true

class Key < ApplicationRecord
  include Keygen::PortableClass
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable
  include Diffable

  belongs_to :policy
  has_one :product, through: :policy
  has_many :event_logs,
    as: :resource

  has_environment default: -> { policy&.environment_id }
  has_account default: -> { policy&.account_id }

  validates :policy,
    scope: { by: :account_id }

  validates :key,
    presence: true,
    allow_blank: false,
    uniqueness: { case_sensitive: true, scope: :account_id },
    exclusion: { in: EXCLUDED_ALIASES, message: "is reserved" },
    length: { minimum: 8, maximum: 1.kilobyte }

  validate on: :create do
    errors.add :policy, :not_supported, message: "cannot be added to an unpooled policy" if !policy.nil? && !policy.pool?
  end

  validate on: [:create, :update] do
    errors.add :key, :conflict, message: "must not conflict with another license's identifier (UUID)" if account.licenses.exists? key
    errors.add :key, :conflict, message: "is already being used as a license's key" if account.licenses.exists? key: key
  end

  scope :for_policy, -> (id) { where policy: id }
  scope :for_product, -> (id) { joins(:policy).where policies: { product_id: id } }
end
