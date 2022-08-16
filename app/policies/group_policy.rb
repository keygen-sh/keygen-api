# frozen_string_literal: true

class GroupPolicy < ApplicationPolicy
  def index?
    verify_permissions!('group.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'product' }
      allow!
    in role: { name: 'user' } if record.all? { _1.id == bearer.group_id || _1.id.in?(bearer.group_ids) }
      allow!
    in role: { name: 'license' } if record.all? { _1.id == bearer.group_id }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('group.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' | 'product' }
      allow!
    in role: { name: 'user' } if record.id == bearer.group_id || record.id.in?(bearer.group_ids)
      allow!
    in role: { name: 'license' } if record.id == bearer.group_id
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('group.create')

    case bearer
    in role: { name: 'admin' | 'developer' | 'product' }
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('group.update')

    case bearer
    in role: { name: 'admin' | 'developer' | 'product' }
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('group.delete')

    case bearer
    in role: { name: 'admin' | 'developer' | 'product' }
      allow!
    else
      deny!
    end
  end
end
