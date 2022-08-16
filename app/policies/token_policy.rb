# frozen_string_literal: true

class TokenPolicy < ApplicationPolicy

  def index?
    verify_permissions!('token.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' } if record.all? { _1.bearer_type == License.name || _1.bearer_type == bearer.class.name && _1.bearer_id == bearer.id }
      allow!
    in role: { name: 'user' | 'license' } if record.all? { _1.bearer_type == bearer.class.name && _1.bearer_id == bearer.id }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('token.read')

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    else
      record.bearer == bearer
    end
  end

  def generate?
    verify_permissions!('token.generate')

    allow!
  end

  def regenerate?
    verify_permissions!('token.regenerate')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      record.bearer == bearer
    end
  end

  def revoke?
    verify_permissions!('token.revoke')

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      record.bearer == bearer
    end
  end
end
