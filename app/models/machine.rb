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
  belongs_to :license, counter_cache: true
  has_one :product, through: :license
  has_one :policy, through: :license
  has_one :user, through: :license

  validates :account, presence: { message: "must exist" }
  validates :license, presence: { message: "must exist" }

  # Disallow machine overages when the policy is not set to concurrent
  validate on: :create do |machine|
    machines_count = machine.license&.machines&.count || 0

    next if machine.policy.nil? ||
            machine.policy.concurrent ||
            machine.license.nil? ||
            machines_count == 0

    next unless (machines_count >= machine.policy.max_machines rescue false)

    machine.errors.add :base, :limit_exceeded, message: "machine count has reached maximum allowed by current policy (#{machine.policy.max_machines || 1})"
  end

  validates :fingerprint, presence: true, blank: false, uniqueness: { scope: :account_id }, if: :uniq_per_account?
  validates :fingerprint, presence: true, blank: false, uniqueness: { scope: :license_id }, if: :uniq_per_license?
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  scope :fingerprint, -> (fingerprint) { where fingerprint: fingerprint }
  scope :hostname, -> (hostname) { where hostname: hostname }
  scope :ip, -> (ip_address) { where ip: ip_address }
  scope :license, -> (id) { where license: id }
  scope :key, -> (key) { joins(:license).where licenses: { key: key } }
  scope :user, -> (id) { joins(:license).where licenses: { user_id: id } }
  scope :product, -> (id) { joins(license: [:policy]).where policies: { product_id: id } }
  scope :policy, -> (id) { joins(license: [:policy]).where policies: { id: id } }

  private

  def uniq_per_account?
    return false if policy.nil?

    policy.fingerprint_uniq_per_account?
  end

  def uniq_per_license?
    return false if policy.nil?

    policy.fingerprint_uniq_per_license?
  end
end
