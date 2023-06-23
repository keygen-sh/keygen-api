# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  def index?
    verify_permissions!('group.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :product | :environment)
      allow!
    in role: Role(:user) if record.all? { _1.id == bearer.group_id || _1.id.in?(bearer.group_ids) }
      allow!
    in role: Role(:license) if record.all? { _1.id == bearer.group_id }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('group.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :product | :environment)
      allow!
    in role: Role(:user) if record.id == bearer.group_id || record.id.in?(bearer.group_ids)
      allow!
    in role: Role(:license) if record.id == bearer.group_id
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('group.create')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :product | :environment)
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('group.update')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :product | :environment)
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('group.delete')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :product | :environment)
      allow!
    else
      deny!
    end
  end
end
