# frozen_string_literal: true

class Machine < ApplicationRecord
  include Sluggable
  include Limitable
  include Pageable
  include Searchable

  HEARTBEAT_DRIFT = 30.seconds
  HEARTBEAT_TTL = 10.minutes

  SEARCH_ATTRIBUTES = %i[id fingerprint name metadata].freeze
  SEARCH_RELATIONSHIPS = {
    product: %i[id name],
    policy: %i[id name],
    license: %i[id key],
    user: %i[id email]
  }.freeze

  search attributes: SEARCH_ATTRIBUTES, relationships: SEARCH_RELATIONSHIPS

  sluggable attributes: %i[id fingerprint]

  belongs_to :account
  belongs_to :license, counter_cache: true
  has_one :product, through: :license
  has_one :policy, through: :license
  has_one :user, through: :license

  # Update license's total core count on machine create, update and destroy
  after_create :update_machines_core_count_on_create
  after_update :update_machines_core_count_on_update
  after_destroy :update_machines_core_count_on_destroy

  validates :account, presence: { message: "must exist" }
  validates :license, presence: { message: "must exist" }

  validates :cores, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 2_147_483_647 }, allow_nil: true

  # Disallow machine fingerprints to match UUID of another machine
  validate on: :create do |machine|
    errors.add :fingerprint, :conflict, message: "must not conflict with another machine's identifier (UUID)" if account.machines.exists? fingerprint
  end

  # Disallow machine overages when the policy is not set to concurrent
  validate on: :create do |machine|
    next if machine.policy.nil? || machine.license.nil?
    next if machine.policy.concurrent?

    machines_count = machine.license.machines.count || 0
    next if machines_count == 0

    next unless (machines_count >= machine.policy.max_machines rescue false)

    machine.errors.add :base, :limit_exceeded, message: "machine count has exceeded maximum allowed by current policy (#{machine.policy.max_machines || 1})"
  end

  # Disallow machine core overages
  validate on: [:create, :update] do |machine|
    next if machine.policy.nil? || machine.license.nil?
    next if machine.policy.max_cores.nil?

    prev_core_count = machine.license.machines.where.not(id: machine.id).sum(:cores) || 0
    next_core_count = prev_core_count + machine.cores.to_i
    next if next_core_count == 0

    next unless (next_core_count > machine.policy.max_cores rescue false)

    machine.errors.add :base, :core_limit_exceeded, message: "machine core count has exceeded maximum allowed by current policy (#{machine.policy.max_cores || 1})"
  end

  # Fingerprint uniqueness on create
  validate on: :create do |machine|
    case
    when uniq_per_account?
      errors.add :fingerprint, :taken, message: "has already been taken for this account" if account.machines.exists?(fingerprint: fingerprint)
    when uniq_per_product?
      errors.add :fingerprint, :taken, message: "has already been taken for this product" if account.machines.joins(:product).exists?(fingerprint: fingerprint, products: { id: product.id })
    when uniq_per_policy?
      errors.add :fingerprint, :taken, message: "has already been taken for this policy" if account.machines.joins(:policy).exists?(fingerprint: fingerprint, policies: { id: policy.id })
    when uniq_per_license?
      errors.add :fingerprint, :taken, message: "has already been taken" if license.machines.exists?(fingerprint: fingerprint)
    end
  end

  validates :fingerprint, presence: true, blank: false, exclusion: { in: Sluggable::EXCLUDED_SLUGS, message: "is reserved" }
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  # FIXME(ezekg) Hack to override pg_search with more performant query
  # TODO(ezekg) Rip out pg_search
  scope :search_fingerprint, -> (term) {
    where('fingerprint ILIKE ?', "%#{term}%")
  }

  scope :metadata, -> (meta) { search_metadata meta }
  scope :fingerprint, -> (fingerprint) { where fingerprint: fingerprint }
  scope :hostname, -> (hostname) { where hostname: hostname }
  scope :ip, -> (ip_address) { where ip: ip_address }
  scope :license, -> (id) { where license: id }
  scope :key, -> (key) { joins(:license).where licenses: { key: key } }
  scope :user, -> (id) { joins(:license).where licenses: { user_id: id } }
  scope :product, -> (id) { joins(license: [:policy]).where policies: { product_id: id } }
  scope :policy, -> (id) { joins(license: [:policy]).where policies: { id: id } }

  def generate_proof(dataset: nil)
    data = JSON.generate(dataset || default_proof_dataset)
    encoded_data = Base64.urlsafe_encode64(data)
    signing_data = "proof/#{encoded_data}"

    priv = OpenSSL::PKey::RSA.new(account.private_key)
    sig = priv.sign(OpenSSL::Digest::SHA256.new, signing_data)
    encoded_sig = Base64.urlsafe_encode64(sig)

    "#{signing_data}.#{encoded_sig}"
  end

  def heartbeat_duration
    policy&.heartbeat_duration || HEARTBEAT_TTL.to_i
  end

  def heartbeat_not_started?
    heartbeat_status == :NOT_STARTED
  end

  def heartbeat_alive?
    heartbeat_status == :ALIVE
  end

  def heartbeat_dead?
    heartbeat_status == :DEAD
  end

  def heartbeat_ok?
    heartbeat_not_started? || heartbeat_alive?
  end

  def next_heartbeat_at
    return nil if last_heartbeat_at.nil?

    last_heartbeat_at + heartbeat_duration
  end

  def requires_heartbeat?
    !last_heartbeat_at.nil?
  end

  def heartbeat_status
    return :NOT_STARTED unless requires_heartbeat?

    if next_heartbeat_at >= Time.current
      :ALIVE
    else
      :DEAD
    end
  end

  private

  def default_proof_dataset
    {
      account: { id: account.id },
      product: { id: product.id },
      policy: { id: policy.id },
      license: {
        id: license.id,
        key: license.key,
        expiry: license.expiry,
      },
      machine: {
        id: id,
        fingerprint: fingerprint,
        created: created_at,
      },
      ts: Time.current,
    }
  end

  def uniq_per_account?
    return false if policy.nil?

    license.policy.fingerprint_uniq_per_account?
  end

  def uniq_per_product?
    return false if policy.nil?

    license.policy.fingerprint_uniq_per_product?
  end

  def uniq_per_policy?
    return false if policy.nil?

    license.policy.fingerprint_uniq_per_policy?
  end

  def uniq_per_license?
    return false if policy.nil?

    license.policy.fingerprint_uniq_per_license?
  end

  # FIXME(ezekg) Maybe there's a better way to do this?
  def update_machines_core_count_on_create
    return if policy.nil? || license.nil?

    prev_core_count = license.machines.where.not(id: id).sum(:cores) || 0
    next_core_count = prev_core_count + cores.to_i
    return if license.machines_core_count == next_core_count

    license.update!(machines_core_count: next_core_count)
  rescue => e
    Rails.logger.error e
  end

  def update_machines_core_count_on_update
    return if policy.nil? || license.nil?

    # Skip unless cores have chagned
    return unless saved_change_to_cores?

    core_count = license.machines.sum(:cores) || 0
    return if license.machines_core_count == core_count

    license.update!(machines_core_count: core_count)
  rescue => e
    Rails.logger.error e
  end

  def update_machines_core_count_on_destroy
    return if policy.nil? || license.nil?

    # Skip if license is being destroyed
    return if license.destroyed?

    core_count = license.machines.where.not(id: id).sum(:cores) || 0
    return if license.machines_core_count == core_count

    license.update!(machines_core_count: core_count)
  rescue => e
    Rails.logger.error e
  end
end
