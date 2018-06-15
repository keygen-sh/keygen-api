class Machine < ApplicationRecord
  include Limitable
  include Pageable
  include Searchable

  SEARCH_ATTRIBUTES = %i[id fingerprint name metadata].freeze
  SEARCH_RELATIONSHIPS = {
    product: %i[id name],
    policy: %i[id name],
    license: %i[id key],
    user: %i[id email]
  }.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  belongs_to :account
  belongs_to :license
  has_one :product, through: :license
  has_one :policy, through: :license
  has_one :user, through: :license

  validates :account, presence: { message: "must exist" }
  validates :license, presence: { message: "must exist" }

  # Disallow machine overages when the policy is not set to concurrent
  validate on: :create do |machine|
    next if machine.policy.nil? ||
            machine.policy.concurrent ||
            machine.license.nil? ||
            machine.license.machines.empty?

    next unless machine.license.machines.count >= machine.policy.max_machines rescue false

    machine.errors.add :base, :limit_exceeded, message: "machine count has reached maximum allowed by current policy (#{machine.policy.max_machines || 1})"
  end

  validates :fingerprint, presence: true, blank: false, uniqueness: { scope: :license_id }
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  scope :fingerprint, -> (fingerprint) { where fingerprint: fingerprint }
  scope :license, -> (id) { where license: id }
  scope :key, -> (key) { joins(:license).where licenses: { key: key } }
  scope :user, -> (id) { joins(:license).where licenses: { user_id: id } }
  scope :product, -> (id) { joins(license: [:policy]).where policies: { product_id: id } }
  scope :policy, -> (id) { joins(license: [:policy]).where policies: { id: id } }
end
