# frozen_string_literal: true

class MachineProcess < ApplicationRecord
  class ResurrectionUnsupportedError < StandardError; end
  class ResurrectionExpiredError < StandardError; end

  include Environmental
  include Accountable
  include Limitable
  include Orderable
  include Pageable

  HEARTBEAT_DRIFT = 30.seconds
  HEARTBEAT_TTL   = 10.minutes

  belongs_to :machine
  has_one :group,      through: :machine
  has_one :license,    through: :machine
  has_one :owner,      through: :machine
  has_many :users,     through: :machine
  has_one :policy,     through: :machine
  has_one :product,    through: :machine

  has_environment default: -> { machine&.environment_id }
  has_account default: -> { machine&.account_id }

  before_validation -> { self.last_heartbeat_at ||= Time.current },
    on: :create

  delegate :process_lease_per_license?, :process_lease_per_machine?, :process_lease_per_user?,
    :resurrect_dead?, :always_resurrect_dead?, :lazarus_ttl,
    allow_nil: true,
    to: :policy

  validates :machine,
    scope: { by: :account_id }

  validates :pid,
    uniqueness: { message: 'has already been taken', scope: %i[machine_id] },
    exclusion: { in: EXCLUDED_ALIASES, message: 'is reserved' },
    presence: true

  validates :last_heartbeat_at,
    presence: true

  validate on: :create, if: -> { id_before_type_cast.present? } do
    errors.add :id, :invalid, message: 'must be a valid UUID' if
      !UUID_RE.match?(id_before_type_cast)

    errors.add :id, :conflict, message: 'must not conflict with another process' if
      MachineProcess.exists?(id)
  end

  validate on: :create do
    next unless
      machine.present? && machine.max_processes.present?

    next if
      license.present? && license.always_allow_overage?

    case
    when lease_per_machine?
      next_process_count = machine.processes.count + 1
      next unless
        next_process_count > machine.max_processes

      next if
        license.allow_1_25x_overage? && next_process_count <= machine.max_processes * 1.25

      next if
        license.allow_1_5x_overage? && next_process_count <= machine.max_processes * 1.5

      next if
        license.allow_2x_overage? && next_process_count <= machine.max_processes * 2

      errors.add :base, :limit_exceeded, message: "process count has exceeded maximum allowed for machine (#{machine.max_processes})"
    when lease_per_license?
      next_process_count = license.processes.count + 1
      next unless
        next_process_count > license.max_processes

      next if
        license.allow_1_25x_overage? && next_process_count <= license.max_processes * 1.25

      next if
        license.allow_1_5x_overage? && next_process_count <= license.max_processes * 1.5

      next if
        license.allow_2x_overage? && next_process_count <= license.max_processes * 2

      errors.add :base, :limit_exceeded, message: "process count has exceeded maximum allowed for license (#{license.max_processes})"
    when lease_per_user?
      next_process_count = license.processes.left_outer_joins(:owner)
                                            .where(owner: { id: owner }) # nil owner is significant
                                            .count + 1
      next unless
        next_process_count > license.max_processes

      next if
        license.allow_1_25x_overage? && next_process_count <= license.max_processes * 1.25

      next if
        license.allow_1_5x_overage? && next_process_count <= license.max_processes * 1.5

      next if
        license.allow_2x_overage? && next_process_count <= license.max_processes * 2

      errors.add :base, :limit_exceeded, message: "process count has exceeded maximum allowed for user (#{license.max_processes})"
    end
  end

  scope :for_product, -> id { joins(:product).where(product: { id: }) }
  scope :for_license, -> id { joins(:license).where(license: { id: }) }
  scope :for_machine, -> id { joins(:machine).where(machine: { id: }) }
  scope :for_user,    -> user {
    processes = User.distinct
                    .reselect(arel_table[Arel.star])
                    .joins(:processes)
                    .reorder(nil)

    case user
    when User, UUID_RE
      from(processes.where(users: { id: user }), table_name)
    else
      from(
        processes.where(users: { id: user })
                 .or(
                   processes.where(users: { email: user }),
                 ),
        table_name,
      )
    end
  }
  scope :for_owner,   -> id { joins(:owner).where(owner: { id: }) }

  scope :alive, -> {
    joins(license: :policy).where(<<~SQL.squish, Time.current, HEARTBEAT_TTL.to_i)
      machine_processes.last_heartbeat_at >= ?::timestamp - INTERVAL '1 second' * COALESCE(policies.heartbeat_duration, ?)
    SQL
  }

  scope :dead, -> {
    joins(license: :policy).where(<<~SQL.squish, Time.current, HEARTBEAT_TTL.to_i)
      machine_processes.last_heartbeat_at < ?::timestamp - INTERVAL '1 second' * COALESCE(policies.heartbeat_duration, ?)
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

  def ping!
    update!(last_heartbeat_at: Time.current)
  end

  def resurrect!
    raise ResurrectionUnsupportedError, 'resurrection is not supported' unless
      resurrect_dead?

    raise ResurrectionExpiredError, 'resurrection period has expired' if
      resurrection_period_passed?

    update!(last_heartbeat_at: Time.current, last_death_event_sent_at: nil)

    self.status_override = 'RESURRECTED'
  end

  def interval
    machine&.heartbeat_duration || HEARTBEAT_TTL.to_i
  end

  def next_heartbeat_at
    last_heartbeat_at + interval
  end

  def monitored? = heartbeat_jid.present?

  def alive?
    status == 'ALIVE' || status == 'RESURRECTED'
  end

  def dead?
    status == 'DEAD'
  end

  def status
    case
    when status_override.present?
      status_override
    when next_heartbeat_at >= Time.current
      'ALIVE'
    else
      'DEAD'
    end
  end

  def lease_per_license? = process_lease_per_license?
  def lease_per_machine? = process_lease_per_machine?
  def lease_per_user?    = process_lease_per_user?

  def resurrection_period_passed?
    return false if
      always_resurrect_dead?

    return true unless
      resurrect_dead?

    Time.current > next_heartbeat_at +
                   lazarus_ttl
  end

  private

  attr_accessor :status_override
end
