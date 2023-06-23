# frozen_string_literal: true

class EnvironmentPolicy < ApplicationPolicy
  def index?
    verify_permissions!('environment.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
      allow!
    else
      deny!
    end
  end

  def show?
    verify_permissions!('environment.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:admin | :developer | :sales_agent | :support_agent | :read_only)
      allow!
    in role: Role(:environment) if record == bearer
      allow!
    else
      deny!
    end
  end

  def create?
    verify_permissions!('environment.create')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer)
      allow!
    else
      deny!
    end
  end

  def update?
    verify_permissions!('environment.update')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer)
      allow!
    else
      deny!
    end
  end

  def destroy?
    verify_permissions!('environment.delete')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer)
      allow!
    else
      deny!
    end
  end

  def me?
    verify_permissions!('environment.read')
    verify_environment!(
      strict: false,
    )

    case bearer
    in role: Role(:environment) if record == bearer
      allow!
    else
      deny!
    end
  end
end
