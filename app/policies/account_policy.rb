# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[create?]

  authorize :account, allow_nil: true

  def index?
    deny!
  end

  def show?
    verify_permissions!('account.read')
    verify_environment!(
      strict: false,
    )

    record == bearer.account
  end

  def create?
    deny! unless unauthenticated?

    allow!
  end

  def update?
    verify_permissions!('account.update')
    verify_environment!

    case bearer
    in role: Role(:admin | :developer)
      record == bearer.account
    else
      deny!
    end
  end

  def destroy?
    deny!
  end
end
