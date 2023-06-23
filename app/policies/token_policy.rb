# frozen_string_literal: true

class TokenPolicy < ApplicationPolicy
  def index?
    verify_permissions!('token.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    in role: Role(:product)
      record.all? { _1 in { bearer_type: ^(Product.name), bearer_id: ^(bearer.id) } |
                          { bearer_type: ^(License.name) | ^(User.name) } }
    in role: Role(:license)
      record.all? { _1 in { bearer_type: ^(License.name), bearer_id: ^(bearer.id) } }
    in role: Role(:user)
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
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment)
      allow!
    else
      record.bearer == bearer
    end
  end

  def generate?
    verify_permissions!('token.generate')
    verify_environment!(
      # NOTE(ezekg) We're lax in the nil environment i.e. we need to be able to generate a token
      #             for a shared environment from the nil environment, but not vice-versa.
      strict: environment.present?,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only | :environment) if record.bearer == bearer
      allow!
    in role: Role(:admin | :developer | :environment) if record.bearer.user?
      allow!
    in role: Role(:user) if record.bearer == bearer
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
    in role: Role(:admin | :developer) if record.bearer == bearer || record.bearer.environment? || record.bearer.product? || record.bearer.license? || record.bearer.user?
      allow!
    in role: Role(:environment) if record.bearer == bearer || record.bearer.product? || record.bearer.license? || record.bearer.user?
      allow!
    else
      record.bearer == bearer
    end
  end

  def revoke?
    verify_permissions!('token.revoke')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    else
      record.bearer == bearer
    end
  end
end
