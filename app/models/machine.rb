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

  validates :account, presence: { message: "must exist" }
  validates :license, presence: { message: "must exist" }

  validate on: :create do |machine|
    errors.add :fingerprint, :conflict, message: "must not conflict with another machine's identifier (UUID)" if account.machines.exists? fingerprint

    # Disallow machine overages when the policy is not set to concurrent
    machines_count = machine.license&.machines&.count || 0

    next if machine.policy.nil? ||
            machine.policy.concurrent ||
            machine.license.nil? ||
            machines_count == 0

    next unless (machines_count >= machine.policy.max_machines rescue false)

    machine.errors.add :base, :limit_exceeded, message: "machine count has reached maximum allowed by current policy (#{machine.policy.max_machines || 1})"
  end

  validates :fingerprint, presence: true, blank: false, uniqueness: { scope: :license_id }, exclusion: { in: Sluggable::EXCLUDED_SLUGS, message: "is reserved" }
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  scope :fingerprint, -> (fingerprint) { where fingerprint: fingerprint }
  scope :hostname, -> (hostname) { where hostname: hostname }
  scope :ip, -> (ip_address) { where ip: ip_address }
  scope :license, -> (id) { where license: id }
  scope :key, -> (key) { joins(:license).where licenses: { key: key } }
  scope :user, -> (id) { joins(:license).where licenses: { user_id: id } }
  scope :product, -> (id) { joins(license: [:policy]).where policies: { product_id: id } }
  scope :policy, -> (id) { joins(license: [:policy]).where policies: { id: id } }

  def heartbeat_duration
    policy&.heartbeat_duration || HEARTBEAT_TTL
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
end
