# frozen_string_literal: true

module Accounts
  class PlanPolicy < ApplicationPolicy
    def show?
      verify_permissions!('account.plan.read')
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

    def update?
      verify_permissions!('account.plan.update')
      verify_environment!

      case bearer
      in role: Role(:admin)
        allow!
      else
        deny!
      end
    end
  end
end
