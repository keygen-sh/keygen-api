# frozen_string_literal: true

class MachinePolicy < ApplicationPolicy
  def index?
    verify_permissions!('machine.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.all? { _1.product.id == bearer.id }
      allow!
    in role: { name: 'user' } if record.all? { _1.license.user_id == bearer.id }
      allow!
    in role: { name: 'user' } if record.any?(&:group_id?) && bearer.group_ids.any?
      record.all? {
        _1.group_id? && _1.group_id.in?(bearer.group_ids) ||
        _1.license.user_id == bearer.id
      }
    in role: { name: 'license' } if record.all? { _1.license_id == bearer.id }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('machine.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      allow!
    in role: { name: 'user' } if record.group_id? && bearer.group_ids.any?
      record.group_id.in?(bearer.group_ids)
    in role: { name: 'license' } if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('machine.create')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.license&.protected?
    in role: { name: 'license' } if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('machine.update')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.license.protected?
    in role: { name: 'license' } if record.license == bearer
      !record.license.protected?
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('machine.delete')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.license.protected?
    in role: { name: 'license' } if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def checkout?
    verify_permissions!('machine.check-out')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    in role: { name: 'user' } if record.user == bearer
      !record.license.protected?
    in role: { name: 'license' } if record.license == bearer
      allow!
    else
      deny!
    end
  end

  def change_group?
    verify_permissions!('machine.group.update')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end
end
