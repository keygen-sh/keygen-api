# frozen_string_literal: true

class MachineProcess < ApplicationRecord
  include Limitable
  include Orderable
  include Pageable

  HEARTBEAT_DRIFT = 30.seconds
  HEARTBEAT_TTL   = 10.minutes

  belongs_to :account
  belongs_to :machine
  has_one :group,      through: :machine
  has_one :license,    through: :machine
  has_one :user,       through: :machine
  has_one :policy,     through: :machine
  has_one :product,    through: :machine

  before_validation -> { self.last_heartbeat_at ||= Time.current },
    on: :create

  delegate :leasing_strategy, :lease_per_license?, :lease_per_machine?,
    :resurrect_dead?, :lazarus_ttl,
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
      !UUID_REGEX.match?(id_before_type_cast)

    errors.add :id, :conflict, message: 'must not conflict with another process' if
      MachineProcess.exists?(id)
  end

  validate on: %i[create update] do
    next unless
      machine.present? && machine.max_processes.present?

    case
    when lease_per_machine?
      next unless
        machine.processes.count >= machine.max_processes

      errors.add :base, :limit_exceeded, message: "process count has exceeded maximum allowed for machine (#{machine.max_processes})"
    when lease_per_license?
      next unless
        license.processes.count >= license.max_processes

      errors.add :base, :limit_exceeded, message: "process count has exceeded maximum allowed for license (#{license.max_processes})"
    end
  end

  scope :for_product, -> product { joins(license: :product).where(products: product) }
  scope :for_license, -> license { joins(:license).where(licenses: license) }
  scope :for_machine, -> machine { where(machine: machine) }
  scope :for_owner,   -> id { joins(group: :owners).where(group: { group_owners: { user_id: id } }) }
  scope :for_user,    -> id {
    joins(:license).where(licenses: { user_id: id })
      .union(
        for_owner(id)
      )
      .distinct
  }

  scope :alive, -> {
    joins(license: :policy).where(<<~SQL.squish, Time.current, HEARTBEAT_TTL)
      machine_processes.last_heartbeat_at >= ?::timestamp - (
        COALESCE(policies.heartbeat_duration, ?) || ' seconds'
      )::interval
    SQL
  }

  scope :dead, -> {
    joins(license: :policy).where(<<~SQL.squish, Time.current, HEARTBEAT_TTL)
      machine_processes.last_heartbeat_at < ?::timestamp - (
        COALESCE(policies.heartbeat_duration, ?) || ' seconds'
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

  def ping!
    update!(last_heartbeat_at: Time.current)
  end

  def resurrect!
    update!(last_heartbeat_at: Time.current, last_death_event_sent_at: nil)

    self.status_override = :RESURRECTED
  end

  def heartbeat_duration
    machine&.heartbeat_duration || HEARTBEAT_TTL.to_i
  end

  def next_heartbeat_at
    last_heartbeat_at + heartbeat_duration
  end

  def alive?
    status == :ALIVE || status == :RESURRECTED
  end

  def dead?
    status == :DEAD
  end

  def status
    case
    when status_override.present?
      status_override
    when next_heartbeat_at >= Time.current
      :ALIVE
    else
      :DEAD
    end
  end

  def resurrection_period_passed?
    return true unless
      resurrect_dead?

    Time.current > next_heartbeat_at +
                   lazarus_ttl
  end

  private

  attr_accessor :status_override
end
