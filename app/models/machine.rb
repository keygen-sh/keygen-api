# frozen_string_literal: true

class Machine < ApplicationRecord
  include Envented::Callbacks
  include Limitable
  include Orderable
  include Pageable
  include Diffable

  HEARTBEAT_DRIFT = 30.seconds
  HEARTBEAT_TTL = 10.minutes

  belongs_to :account
  belongs_to :license, counter_cache: true
  belongs_to :group,
    optional: true
  has_one :product, through: :license
  has_one :policy, through: :license
  has_one :user, through: :license
  has_many :event_logs,
    as: :resource

  # Machines automatically inherit their license's group ID
  before_validation -> { self.group_id = license.group_id },
    if: -> { license.present? && group_id.nil? },
    on: %i[create]

  # Update license's total core count on machine create, update and destroy
  after_create :update_machines_core_count_on_create
  after_update :update_machines_core_count_on_update
  after_destroy :update_machines_core_count_on_destroy

  # Notify license of creation event (in case license isn't whodunnit)
  on_exclusive_event 'machine.created', -> { license.notify_of_event!('machine.created') },
    auto_release_lock: true

  validates :license,
    scope: { by: :account_id }
  validates :group,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> {
      group_id_before_type_cast.nil?
    }

  validates :cores, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 2_147_483_647 }, allow_nil: true

  validate on: :create, if: -> { id_before_type_cast.present? } do
    errors.add :id, :invalid, message: 'must be a valid UUID' if
      !UUID_REGEX.match?(id_before_type_cast)

    errors.add :id, :conflict, message: 'must not conflict with another machine' if
      Machine.exists?(id)
  end

  # Disallow machine fingerprints to match UUID of another machine
  validate on: :create do |machine|
    errors.add :fingerprint, :conflict, message: "must not conflict with another machine's identifier (UUID)" if account.machines.exists? fingerprint
  end

  # Disallow machine overages when the policy is not set to concurrent
  validate on: :create do |machine|
    next if machine.license.nil?
    next if
      machine.license.max_machines.nil? ||
      machine.license.concurrent?

    machines_count = machine.license.machines_count || 0
    next if
      machines_count == 0

    next unless
      machines_count >= machine.license.max_machines

    machine.errors.add :base, :limit_exceeded, message: "machine count has exceeded maximum allowed by current policy (#{machine.license.max_machines})"
  end

  # Disallow machine core overages for non-concurrent licenses
  validate on: [:create, :update] do |machine|
    next if machine.license.nil?
    next if
      machine.license.max_cores.nil? ||
      machine.license.concurrent?

    prev_core_count = machine.license.machines.where.not(id: machine.id).sum(:cores) || 0
    next_core_count = prev_core_count + machine.cores.to_i
    next if
      next_core_count == 0

    next unless
      next_core_count > machine.license.max_cores

    machine.errors.add :base, :core_limit_exceeded, message: "machine core count has exceeded maximum allowed by current policy (#{machine.license.max_cores})"
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

  validate on: %i[create update] do
    next unless
      group_id_changed?

    next unless
      group.present? && group.max_machines.present?

    next unless
      group.machines.count >= group.max_machines

    errors.add :group, :machine_limit_exceeded, message: "machine count has exceeded maximum allowed by current group (#{group.max_machines})"
  end

  validates :fingerprint, presence: true, allow_blank: false, exclusion: { in: EXCLUDED_ALIASES, message: "is reserved" }
  validates :metadata, length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_REGEX.match?(identifier)

    where('machines.id::text ILIKE ?', "%#{identifier}%")
  }

  scope :search_fingerprint, -> (term) {
    where('machines.fingerprint ILIKE ?', "%#{term}%")
  }

  scope :search_name, -> (term) {
    where('machines.name ILIKE ?', "%#{term}%")
  }

  scope :search_metadata, -> (terms) {
    # FIXME(ezekg) Duplicated code for licenses, users, and machines.
    # FIXME(ezekg) Need to figure out a better way to do this. We need to be able
    #              to search for the original string values and type cast, since
    #              HTTP querystring parameters are strings.
    #
    #              Example we need to be able to search for:
    #
    #                { metadata: { external_id: "1624214616", internal_id: 1 } }
    #
    terms.reduce(self) do |scope, (key, value)|
      search_key       = key.to_s.underscore.parameterize(separator: '_')
      before_type_cast = { search_key => value }
      after_type_cast  =
        case value
        when 'true'
          { search_key => true }
        when 'false'
          { search_key => false }
        when 'null'
          { search_key => nil }
        when /^\d+$/
          { search_key => value.to_i }
        when /^\d+\.\d+$/
          { search_key => value.to_f }
        else
          { search_key => value }
        end

      scope.where('machines.metadata @> ?', before_type_cast.to_json)
        .or(
          scope.where('machines.metadata @> ?', after_type_cast.to_json)
        )
    end
  }

  scope :search_license, -> (term) {
    license_identifier = term.to_s
    return none if
      license_identifier.empty?

    return where(license_id: license_identifier) if
      UUID_REGEX.match?(license_identifier)

    tsv_query = <<~SQL
      to_tsvector('simple', licenses.id::text)
      @@
      to_tsquery(
        'simple',
        ''' ' ||
        ?     ||
        ' ''' ||
        ':*'
      )
    SQL

    joins(:license).where('licenses.name ILIKE ?', "%#{license_identifier}%")
                   .or(
                     joins(:license).where(tsv_query.squish, license_identifier.gsub(SANITIZE_TSV_RX, ' '))
                   )
  }

  scope :search_user, -> (term) {
    user_identifier = term.to_s
    return none if
      user_identifier.empty?

    return joins(:user).where(user: { id: user_identifier }) if
      UUID_REGEX.match?(user_identifier)

    tsv_query = <<~SQL
      to_tsvector('simple', users.id::text)
      @@
      to_tsquery(
        'simple',
        ''' ' ||
        ?     ||
        ' ''' ||
        ':*'
      )
    SQL

    joins(:user).where('users.email ILIKE ?', "%#{user_identifier}%")
                .or(
                  joins(:user).where(tsv_query.squish, user_identifier.gsub(SANITIZE_TSV_RX, ' '))
                )
  }

  scope :search_product, -> (term) {
    product_identifier = term.to_s
    return none if
      product_identifier.empty?

    return joins(:policy).where(policy: { product_id: product_identifier }) if
      UUID_REGEX.match?(product_identifier)

    tsv_query = <<~SQL
      to_tsvector('simple', products.id::text)
      @@
      to_tsquery(
        'simple',
        ''' ' ||
        ?     ||
        ' ''' ||
        ':*'
      )
    SQL

    joins(policy: :product)
      .where('products.name ILIKE ?', "%#{product_identifier}%")
      .or(
        joins(policy: :product).where(tsv_query.squish, product_identifier.gsub(SANITIZE_TSV_RX, ' '))
      )
  }

  scope :search_policy, -> (term) {
    policy_identifier = term.to_s
    return none if
      policy_identifier.empty?

    return where(policy_id: policy_identifier) if
      UUID_REGEX.match?(policy_identifier)

    tsv_query = <<~SQL
      to_tsvector('simple', policy_id::text)
      @@
      to_tsquery(
        'simple',
        ''' ' ||
        ?     ||
        ' ''' ||
        ':*'
      )
    SQL

    joins(:policy).where('policies.name ILIKE ?', "%#{policy_identifier}%")
                  .or(
                    joins(:policy).where(tsv_query.squish, policy_identifier.gsub(SANITIZE_TSV_RX, ' '))
                  )
  }

  scope :with_metadata, -> (meta) { search_metadata meta }
  scope :with_fingerprint, -> (fingerprint) { where fingerprint: fingerprint }
  scope :with_hostname, -> (hostname) { where hostname: hostname }
  scope :with_ip, -> (ip_address) { where ip: ip_address }
  scope :for_license, -> (id) { where license: id }
  scope :for_key, -> (key) { joins(:license).where licenses: { key: key } }
  scope :for_owner, -> id { joins(group: :owners).where(group: { group_owners: { user_id: id } }) }
  scope :for_user, -> (id) {
    joins(:license).where(licenses: { user_id: id })
      .union(
        for_owner(id)
      )
      .distinct
  }
  scope :for_product, -> (id) { joins(license: [:policy]).where policies: { product_id: id } }
  scope :for_policy, -> (id) { joins(license: [:policy]).where policies: { id: id } }
  scope :for_group, -> id { where(group: id) }

  scope :alive, -> {
    joins(license: :policy)
      .where(last_heartbeat_at: nil)
      .or(
        joins(license: :policy).where(<<~SQL.squish, Time.current, HEARTBEAT_TTL)
          last_heartbeat_at >= ?::timestamp - (
            COALESCE(heartbeat_duration, ?) || ' seconds'
          )::interval
        SQL
      )
  }

  scope :dead, -> {
    joins(license: :policy)
      .where.not(last_heartbeat_at: nil)
      .where(<<~SQL.squish, Time.current, HEARTBEAT_TTL)
        last_heartbeat_at < ?::timestamp - (
          COALESCE(heartbeat_duration, ?) || ' seconds'
        )::interval
      SQL
  }

  scope :with_status, -> status {
    case status.to_s.upcase
    when 'ALIVE'
      self.alive
    when 'DEAD'
      self.dead
    else
      self.none
    end
  }

  delegate :resurrect_dead_machines?, :lazarus_ttl,
    allow_nil: true,
    to: :policy

  def generate_proof(dataset: nil)
    data = JSON.generate(dataset || default_proof_dataset)
    encoded_data = Base64.urlsafe_encode64(data)
    signing_data = "proof/#{encoded_data}"

    priv = OpenSSL::PKey::RSA.new(account.private_key)
    sig = priv.sign(OpenSSL::Digest::SHA256.new, signing_data)
    encoded_sig = Base64.urlsafe_encode64(sig)

    "#{signing_data}.#{encoded_sig}"
  end

  def ping!
    update!(last_heartbeat_at: Time.current)
  end

  def resurrect!
    update!(last_heartbeat_at: Time.current, last_death_event_sent_at: nil)

    self.heartbeat_status_override = :RESURRECTED
  end

  def heartbeat_duration
    policy&.heartbeat_duration || HEARTBEAT_TTL.to_i
  end

  def heartbeat_not_started?
    heartbeat_status == :NOT_STARTED
  end
  alias_method :not_started?, :heartbeat_not_started?

  def heartbeat_alive?
    heartbeat_status == :ALIVE
  end
  alias_method :alive?, :heartbeat_alive?

  def heartbeat_dead?
    heartbeat_status == :DEAD
  end
  alias_method :dead?, :heartbeat_dead?

  def heartbeat_ok?
    heartbeat_not_started? || heartbeat_alive?
  end
  alias_method :ok?, :heartbeat_ok?

  def next_heartbeat_at
    return nil if last_heartbeat_at.nil?

    last_heartbeat_at + heartbeat_duration
  end

  def requires_heartbeat?
    policy&.require_heartbeat? || !last_heartbeat_at.nil?
  end

  def heartbeat_status
    return heartbeat_status_override if
      heartbeat_status_override.present?

    return :NOT_STARTED unless
      requires_heartbeat? &&
      last_heartbeat_at?

    if next_heartbeat_at >= Time.current
      :ALIVE
    else
      :DEAD
    end
  end

  def resurrection_period_passed?
    return true unless
      resurrect_dead_machines? &&
      requires_heartbeat?

    Time.current > next_heartbeat_at +
                   lazarus_ttl
  end

  private

  attr_accessor :heartbeat_status_override

  def default_proof_dataset
    {
      account: { id: account.id },
      product: { id: product.id },
      policy: { id: policy.id, duration: policy.duration },
      license: {
        id: license.id,
        key: license.key,
        expiry: license.expiry&.iso8601(3),
      },
      machine: {
        id: id,
        fingerprint: fingerprint,
        created: created_at.iso8601(3),
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
    Keygen.logger.exception e
  end

  def update_machines_core_count_on_update
    return if policy.nil? || license.nil?

    # Skip unless cores have changed
    return unless saved_change_to_cores?

    core_count = license.machines.sum(:cores) || 0
    return if license.machines_core_count == core_count

    license.update!(machines_core_count: core_count)
  rescue => e
    Keygen.logger.exception e
  end

  def update_machines_core_count_on_destroy
    return if policy.nil? || license.nil?

    # Skip if license is being destroyed
    return if license.destroyed?

    core_count = license.machines.where.not(id: id).sum(:cores) || 0
    return if license.machines_core_count == core_count

    license.update!(machines_core_count: core_count)
  rescue => e
    Keygen.logger.exception e
  end
end
