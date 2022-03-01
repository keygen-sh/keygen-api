class GroupMember < ApplicationRecord
  include Limitable
  include Pageable

  belongs_to :account
  belongs_to :group
  belongs_to :member,
    polymorphic: true

  validates :account,
    presence: true
  validates :group,
    scope: { by: :account_id },
    presence: true
  validates :member,
    scope: { by: :account_id },
    presence: true

  validate on: :create do
    next unless
      group.max_users.present?

    next unless
      group.users.count >= group.max_users

    errors.add :base, :user_limit_exceeded, message: "users count has exceeded maximum allowed by current group (#{group.max_users})"
  end

  validate on: :create do
    next unless
      group.max_licenses.present?

    next unless
      group.licenses.count >= group.max_licenses

    errors.add :base, :license_limit_exceeded, message: "licenses count has exceeded maximum allowed by current group (#{group.max_licenses})"
  end

  validate on: :create do
    next unless
      group.max_machines.present?

    next unless
      group.machines.count >= group.max_machines

    errors.add :base, :machine_limit_exceeded, message: "machines count has exceeded maximum allowed by current group (#{group.max_machines})"
  end
end
