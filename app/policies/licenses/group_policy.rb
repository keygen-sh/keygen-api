# frozen_string_literal: true

class Licenses::GroupPolicy < ApplicationPolicy
  authorize :license

  def show?
    verify_permissions!('license.group.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' }
      allow!
    in role: { name: 'product' } if license.product == bearer
      allow!
    in role: { name: 'user' } if license.user == bearer || record.id == bearer.group_id || record.id.in?(bearer.group_ids)
      allow!
    in role: { name: 'license' } if license == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('license.group.update')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' }
      allow!
    in role: { name: 'product' } if license.product == bearer
      allow!
    else
      deny!
    end
  end
end
