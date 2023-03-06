# frozen_string_literal: true

class TokenPolicy < ApplicationPolicy
  def index?
    verify_permissions!('token.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'product' }
      record.all? { _1 in { bearer_type: ^(Product.name), bearer_id: ^(bearer.id) } |
                          { bearer_type: ^(License.name) | ^(User.name) } }
    in role: { name: 'license' }
      record.all? { _1 in { bearer_type: ^(License.name), bearer_id: ^(bearer.id) } }
    in role: { name: 'user' }
      record.all? { _1 in { bearer_type: ^(User.name), bearer_id: ^(bearer.id) } }
    else
      deny!
    end
  end

  def show?
    verify_permissions!('token.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    else
      record.bearer == bearer
    end
  end

  def generate?
    verify_permissions!('token.generate')
    verify_environment!

    case bearer
    in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
      allow!
    in role: { name: 'user' }
      deny! 'user is banned' if
        bearer.banned?

      allow!
    else
      deny!
    end
  end

  def regenerate?
    verify_permissions!('token.regenerate')
    verify_environment!

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      record.bearer == bearer
    end
  end

  def revoke?
    verify_permissions!('token.revoke')
    verify_environment!

    case bearer
    in role: { name: 'admin' | 'developer' }
      allow!
    else
      record.bearer == bearer
    end
  end
end
