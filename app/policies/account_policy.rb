# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  skip_pre_check :verify_authenticated!, only: %i[create?]

  def index?
    deny!
  end

  def show?
    verify_permissions!('account.read')

    record == bearer.account
  end

  def create?
    deny! unless unauthenticated?

    allow!
  end

  def update?
    verify_permissions!('account.update')

    case bearer
    in role: { name: 'admin' | 'developer' }
      record == bearer.account
    else
      deny!
    end
  end

  def destroy?
    deny!
  end
end
