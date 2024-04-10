# frozen_string_literal: true

class Machine < ApplicationRecord
  class ResurrectionUnsupportedError < StandardError; end
  class ResurrectionExpiredError < StandardError; end

  include Envented::Callbacks
  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable
  include Diffable
  include Dirtyable

  HEARTBEAT_DRIFT = 30.seconds
  HEARTBEAT_TTL = 10.minutes

  belongs_to :license, counter_cache: true
  belongs_to :owner,
    class_name: User.name,
    optional: true
  belongs_to :group,
    optional: true
  has_one :product, through: :license
  has_one :policy, through: :license
  has_many :users, through: :license
  has_many :processes,
    class_name: 'MachineProcess',
    inverse_of: :machine,
    dependent: :delete_all
  has_many :components,
    class_name: 'MachineComponent',
    inverse_of: :machine,
    dependent: :delete_all,
    index_errors: true,
    autosave: true
  has_many :event_logs,
    as: :resource

  has_environment default: -> { license&.environment_id }
  has_account default: -> { license&.account_id }

  accepts_nested_attributes_for :components, limit: 20, reject_if: :reject_associated_records_for_components
  tracks_nested_attributes_for :components

  # Machines firstly automatically inherit their license's group ID.
  before_validation -> { self.group_id = license.group_id },
    if: -> { license.present? && group_id.nil? },
    on: %i[create]

  # Machines secondly automatically inherit their owner's group ID. We're using before_validation
  # instead of before_create so that this can be run when the owner is changed as well,
  # and so that we can keep our group limit validations in play.
  before_validation -> { self.group_id = owner.group_id },
    if: -> { owner_id_changed? && owner.present? && group_id.nil? },
    on: %i[create update]

  # Set initial heartbeat if heartbeat is required
  before_validation -> { self.last_heartbeat_at ||= Time.current },
    if: :heartbeat_from_creation?,
    on: :create

  # Update license's total core count on machine create, update and destroy
  after_create :update_machines_core_count_on_create
  after_update :update_machines_core_count_on_update
  after_destroy :update_machines_core_count_on_destroy

  # Notify license of creation event (in case license isn't whodunnit)
  on_exclusive_event 'machine.created', -> { license.notify!('machine.created') },
    auto_release_lock: true

  validates :license,
    scope: { by: :account_id }

  validates :owner,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> {
      owner_id_before_type_cast.nil?
    }

  validates :group,
    presence: { message: 'must exist' },
    scope: { by: :account_id },
    unless: -> {
      group_id_before_type_cast.nil?
    }

  validates :fingerprint,
    uniqueness: { message: 'has already been taken', scope: %i[license_id] },
    exclusion: { in: EXCLUDED_ALIASES, message: "is reserved" },
    allow_blank: false,
    presence: true

  validates :metadata,
    length: { maximum: 64, message: "too many keys (exceeded limit of 64 keys)" }

  validates :cores,
    numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 2_147_483_647 },
    allow_nil: true

  validates :max_processes,
    numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 2_147_483_647 },
    if: :max_processes_override?,
    allow_nil: true

  validate on: :create, if: -> { id_before_type_cast.present? } do
    errors.add :id, :invalid, message: 'must be a valid UUID' if
      !UUID_RE.match?(id_before_type_cast)

    errors.add :id, :conflict, message: 'must not conflict with another machine' if
      Machine.exists?(id)
  end

  # Disallow machine fingerprints to match UUID of another machine
  validate on: :create do |machine|
    errors.add :fingerprint, :conflict, message: "must not conflict with another machine's identifier (UUID)" if account.machines.exists? fingerprint
  end

  # Disallow machine overages according to policy overage strategy
  validate on: :create do |machine|
    next if machine.license.nil?
    next if
      machine.license.max_machines.nil? || machine.license.always_allow_overage?

    prev_machines_count = machine.license.machines_count || 0
    next if
      prev_machines_count == 0

    next_machine_count = prev_machines_count + 1
    next unless
      next_machine_count > machine.license.max_machines

    next if
      machine.license.allow_1_25x_overage? && next_machine_count <= machine.license.max_machines * 1.25

    next if
      machine.license.allow_1_5x_overage? && next_machine_count <= machine.license.max_machines * 1.5

    next if
      machine.license.allow_2x_overage? && next_machine_count <= machine.license.max_machines * 2

    machine.errors.add :base, :limit_exceeded, message: "machine count has exceeded maximum allowed by current policy (#{machine.license.max_machines})"
  end

  # Disallow machine core overages according to policy overage strategy
  validate on: [:create, :update] do |machine|
    next if machine.license.nil?
    next if
      machine.license.max_cores.nil? || machine.license.always_allow_overage?

    prev_core_count = machine.license.machines.where.not(id: machine.id).sum(:cores) || 0
    next_core_count = prev_core_count + machine.cores.to_i
    next if
      next_core_count == 0

    next unless
      next_core_count > machine.license.max_cores

    next if
      machine.license.allow_1_25x_overage? && next_core_count <= machine.license.max_cores * 1.25

    next if
      machine.license.allow_1_5x_overage? && next_core_count <= machine.license.max_cores * 1.5

    next if
      machine.license.allow_2x_overage? && next_core_count <= machine.license.max_cores * 2

    machine.errors.add :base, :core_limit_exceeded, message: "machine core count has exceeded maximum allowed by current policy (#{machine.license.max_cores})"
  end

  # Fingerprint uniqueness on create
  validate on: :create do |machine|
    case
    when unique_per_account?
      errors.add :fingerprint, :taken, message: "has already been taken for this account" if account.machines.exists?(fingerprint:)
    when unique_per_product?
      errors.add :fingerprint, :taken, message: "has already been taken for this product" if account.machines.joins(:product).exists?(fingerprint:, products: { id: product.id })
    when unique_per_policy?
      errors.add :fingerprint, :taken, message: "has already been taken for this policy" if account.machines.joins(:policy).exists?(fingerprint:, policies: { id: policy.id })
    when unique_per_license?
      errors.add :fingerprint, :taken, message: "has already been taken" if license.machines.exists?(fingerprint:)
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

  # Assert owner is a license user (i.e. licensee or owner)
  validate on: %i[create update] do
    next unless
      owner_id_changed?

    next unless
      owner.present?

    unless license.users.exists?(owner.id)
      errors.add :owner, :invalid, message: 'must be a valid license user'
    end
  end

  scope :search_id, -> (term) {
    identifier = term.to_s
    return none if
      identifier.empty?

    return where(id: identifier) if
      UUID_RE.match?(identifier)

    where('machines.id::text ILIKE ?', "%#{sanitize_sql_like(identifier)}%")
  }

  scope :search_fingerprint, -> (term) {
    return none if
      term.blank?

    where('machines.fingerprint ILIKE ?', "%#{sanitize_sql_like(term)}%")
  }

  scope :search_name, -> (term) {
    return none if
      term.blank?

    where('machines.name ILIKE ?', "%#{sanitize_sql_like(term)}%")
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
      UUID_RE.match?(license_identifier)

    scope = joins(:license).where('licenses.name ILIKE ?', "%#{sanitize_sql_like(license_identifier)}%")
    return scope unless
      UUID_CHAR_RE.match?(license_identifier)

    scope.or(
      joins(:license).where(<<~SQL.squish, license_identifier.gsub(SANITIZE_TSV_RE, ' '))
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
    )
  }

  scope :search_owner, -> (term) {
    owner_identifier = term.to_s
    return none if
      owner_identifier.empty?

    return joins(:owner).where(owner: { id: owner_identifier }) if
      UUID_RE.match?(owner_identifier)

    scope = joins(:owner).where(owner: { email: owner_identifier })
                         .or(
                           joins(:owner).where('owner.email ILIKE ?', "%#{sanitize_sql_like(owner_identifier)}%"),
                         )
    return scope unless
      UUID_CHAR_RE.match?(owner_identifier)

    scope.or(
      joins(:owner).where(<<~SQL.squish, owner_identifier.gsub(SANITIZE_TSV_RE, ' '))
        to_tsvector('simple', owner.id::text)
        @@
        to_tsquery(
          'simple',
          ''' ' ||
          ?     ||
          ' ''' ||
          ':*'
        )
      SQL
    )
  }

  scope :search_user, -> (term) {
    user_identifier = term.to_s
    return none if
      user_identifier.empty?

    return joins(:users).where(users: { id: user_identifier }) if
      UUID_RE.match?(user_identifier)

    scope = joins(:users).where(users: { email: user_identifier })
                         .or(
                           joins(:users).where('users.email ILIKE ?', "%#{sanitize_sql_like(user_identifier)}%"),
                         )
    return scope unless
      UUID_CHAR_RE.match?(user_identifier)

    scope.or(
      joins(:users).where(<<~SQL.squish, user_identifier.gsub(SANITIZE_TSV_RE, ' '))
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
    )
  }

  scope :search_product, -> (term) {
    product_identifier = term.to_s
    return none if
      product_identifier.empty?

    return joins(:policy).where(policy: { product_id: product_identifier }) if
      UUID_RE.match?(product_identifier)

    scope = joins(policy: :product).where('products.name ILIKE ?', "%#{sanitize_sql_like(product_identifier)}%")
    return scope unless
      UUID_CHAR_RE.match?(product_identifier)

    scope.or(
      joins(policy: :product).where(<<~SQL.squish, product_identifier.gsub(SANITIZE_TSV_RE, ' '))
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
    )
  }

  scope :search_policy, -> (term) {
    policy_identifier = term.to_s
    return none if
      policy_identifier.empty?

    return joins(:policy).where(policy: { id: policy_identifier }) if
      UUID_RE.match?(policy_identifier)

    scope = joins(:policy).where('policies.name ILIKE ?', "%#{sanitize_sql_like(policy_identifier)}%")
    return scope unless
      UUID_CHAR_RE.match?(policy_identifier)

    scope.or(
      joins(:policy).where(<<~SQL.squish, policy_identifier.gsub(SANITIZE_TSV_RE, ' '))
        to_tsvector('simple', policies.id::text)
        @@
        to_tsquery(
          'simple',
          ''' ' ||
          ?     ||
          ' ''' ||
          ':*'
        )
      SQL
    )
  }

  scope :with_metadata, -> (meta) { search_metadata meta }
  scope :with_fingerprint, -> (fingerprint) { where fingerprint: fingerprint }
  scope :with_hostname, -> (hostname) { where hostname: hostname }
  scope :with_ip, -> (ip_address) { where ip: ip_address }
  scope :for_license, -> (id) { where license: id }
  scope :for_key, -> (key) { joins(:license).where licenses: { key: key } }
  scope :for_group_owner, -> id { joins(group: :owners).where(group: { group_owners: { user_id: id } }) }
  scope :for_user, -> user {
    machines = User.distinct
                   .reselect(arel_table[Arel.star])
                   .joins(:machines)
                   .reorder(nil)

    case user
    when User, UUID_RE
      from(machines.where(users: { id: user }), table_name)
    else
      from(
        machines.where(users: { id: user })
                .or(
                  machines.where(users: { email: user }),
                ),
        table_name,
      )
    end
  }
  scope :for_owner, -> owner {
    case owner
    when User, UUID_RE, nil
      where(owner:)
    else
      joins(:owner).where(owner: { id: owner })
                   .or(
                     joins(:owner).where(owner: { email: owner }),
                   )
    end
  }

  scope :for_product, -> id { joins(:license).where(license: { product_id: id }) }
  scope :for_policy, -> id { joins(:license).where license: { policy_id: id } }
  scope :for_group, -> id { where(group: id) }

  scope :alive, -> {
    idle_machines  = joins(license: :policy).where(last_heartbeat_at: nil, policies: { require_heartbeat: false })
    new_machines   = joins(license: :policy).where(last_heartbeat_at: nil, policies: { require_heartbeat: true })
                                            .where(<<~SQL.squish, Time.current, HEARTBEAT_TTL.to_i)
                                              machines.created_at >= ?::timestamp - (
                                                COALESCE(policies.heartbeat_duration, ?) || ' seconds'
                                              )::interval
                                            SQL
    alive_machines = joins(license: :policy).where.not(last_heartbeat_at: nil)
                                            .where(<<~SQL.squish, Time.current, HEARTBEAT_TTL.to_i)
                                              machines.last_heartbeat_at >= ?::timestamp - (
                                                COALESCE(policies.heartbeat_duration, ?) || ' seconds'
                                              )::interval
                                            SQL

    idle_machines.or(new_machines)
                 .or(alive_machines)
  }

  scope :dead, -> {
    expired_machines = joins(license: :policy).where(last_heartbeat_at: nil, policies: { require_heartbeat: true })
                                              .where(<<~SQL.squish, Time.current, HEARTBEAT_TTL.to_i)
                                                machines.created_at < ?::timestamp - (
                                                  COALESCE(policies.heartbeat_duration, ?) || ' seconds'
                                                )::interval
                                              SQL
    dead_machines    = joins(license: :policy).where.not(last_heartbeat_at: nil)
                                              .where(<<~SQL.squish, Time.current, HEARTBEAT_TTL.to_i)
                                                machines.last_heartbeat_at < ?::timestamp - (
                                                  COALESCE(policies.heartbeat_duration, ?) || ' seconds'
                                                )::interval
                                              SQL

    expired_machines.or(dead_machines)
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

  delegate :heartbeat_from_creation?, :heartbeat_from_first_ping?,
    :resurrect_dead?, :always_resurrect_dead?, :lazarus_ttl,
    allow_nil: true,
    to: :policy

  def group!
    raise Keygen::Error::NotFoundError.new(model: Group.name) unless
      group.present?

    group
  end

  def max_processes=(value)
    self.max_processes_override = value
  end

  def max_processes
    return max_processes_override if
      max_processes_override?

    license&.max_processes
  end

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
    raise ResurrectionUnsupportedError, 'resurrection is not supported' unless
      resurrect_dead?

    raise ResurrectionExpiredError, 'resurrection period has expired' if
      resurrection_period_passed?

    update!(last_heartbeat_at: Time.current, last_death_event_sent_at: nil)

    self.heartbeat_status_override = 'RESURRECTED'
  end

  def heartbeat_duration
    policy&.heartbeat_duration || HEARTBEAT_TTL.to_i
  end

  def heartbeat_monitored? = heartbeat_jid.present?
  alias_method :monitored?, :heartbeat_monitored?

  def heartbeat_not_started?
    heartbeat_status == 'NOT_STARTED'
  end
  alias_method :not_started?, :heartbeat_not_started?

  def heartbeat_alive?
    heartbeat_status == 'ALIVE' || heartbeat_status == 'RESURRECTED'
  end
  alias_method :alive?, :heartbeat_alive?

  def heartbeat_dead?
    heartbeat_status == 'DEAD'
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

  def heartbeat? = next_heartbeat_at.present?

  def requires_heartbeat?
    policy&.require_heartbeat? || !last_heartbeat_at.nil?
  end

  def heartbeat_status
    case
    when heartbeat_status_override.present?
      heartbeat_status_override
    when !heartbeat? && (!requires_heartbeat? || created_at >= Time.current - heartbeat_duration)
      'NOT_STARTED'
    when heartbeat? && next_heartbeat_at >= Time.current
      'ALIVE'
    else
      'DEAD'
    end
  end
  alias_method :status, :heartbeat_status

  def resurrection_period_passed?
    return false if
      always_resurrect_dead?

    return true unless
      requires_heartbeat? &&
      resurrect_dead? &&
      heartbeat?

    Time.current > next_heartbeat_at +
                   lazarus_ttl
  end

  def unique_per_account?
    return false if policy.nil?

    policy.machine_unique_per_account?
  end

  def unique_per_product?
    return false if policy.nil?

    policy.machine_unique_per_product?
  end

  def unique_per_policy?
    return false if policy.nil?

    policy.machine_unique_per_policy?
  end

  def unique_per_license?
    return false if policy.nil?

    policy.machine_unique_per_license?
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
    return if
      license.marked_for_destruction? ||
      license.destroyed?

    core_count = license.machines.where.not(id: id).sum(:cores) || 0
    return if license.machines_core_count == core_count

    license.update!(machines_core_count: core_count)
  rescue => e
    Keygen.logger.exception e
  end

  def reject_associated_records_for_components(attrs)
    return if
      new_record?

    components.exists?(
      # Make sure we only select real columns, not e.g. _destroy.
      attrs.slice(attributes.keys),
    )
  end
end
