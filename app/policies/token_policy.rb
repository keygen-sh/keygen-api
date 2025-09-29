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
    in role: Role(:product), id: bearer_id
      record.all? { _1 in { bearer_type: 'Product', bearer_id: ^bearer_id } | { bearer_type: 'License' | 'User' } }
    in role: Role(:license), id: bearer_id
      record.all? { _1 in { bearer_type: 'License', bearer_id: ^bearer_id } }
    in role: Role(:user), id: bearer_id
      record.all? { _1 in { bearer_type: 'User', bearer_id: ^bearer_id } }
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
    in role: Role(:product) if record.user_token? && record.bearer.products.exists?(bearer.id)
      allow!
    in role: Role(:product) if record.license_token? && record.bearer.product == bearer
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
    in role: Role(:admin | :developer | :environment) if record.user_token?
      allow!
    in role: Role(:product) if record.user_token? && record.bearer.products.exists?(bearer.id)
      allow!
    in role: Role(:product) if record.license_token? && record.bearer.product == bearer
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
    in role: Role(:admin | :developer) if record.bearer == bearer || record.environment_token? || record.product_token? || record.license_token? || record.user_token?
      allow!
    in role: Role(:environment) if record.bearer == bearer || record.product_token? || record.license_token? || record.user_token?
      allow!
    in role: Role(:product) if record.user_token? && record.bearer.products.exists?(bearer.id)
      allow!
    in role: Role(:product) if record.license_token? && record.bearer.product == bearer
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
    in role: Role(:product) if record.user_token? && record.bearer.products.exists?(bearer.id)
      allow!
    in role: Role(:product) if record.license_token? && record.bearer.product == bearer
      allow!
    else
      record.bearer == bearer
    end
  end
end
