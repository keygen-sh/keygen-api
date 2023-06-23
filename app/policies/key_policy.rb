# frozen_string_literal: true

class KeyPolicy < ApplicationPolicy
  def index?
    verify_permissions!('key.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :read_only | :sales_agent | :support_agent | :environment)
      allow!
    in role: Role(:product) if record.all? { _1.product == bearer }
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('key.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :read_only | :sales_agent | :support_agent | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('key.create')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('key.update')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('key.delete')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer | :environment)
      allow!
    in role: Role(:product) if record.product == bearer
      allow!
    else
      deny!
    end
  end
end
