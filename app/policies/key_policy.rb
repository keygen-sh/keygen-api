# frozen_string_literal: true

class KeyPolicy < ApplicationPolicy
  def index?
    verify_permissions!('key.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if record.all? { _1.product == bearer }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('key.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'read_only' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('key.create')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('key.update')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('key.delete')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    in role: { name: 'product' } if record.product == bearer
      allow!
    else
      deny!
    end
  end
end
