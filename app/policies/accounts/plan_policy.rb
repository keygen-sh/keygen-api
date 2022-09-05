# frozen_string_literal: true

module Accounts
  class PlanPolicy < ApplicationPolicy
    def show?
      verify_permissions!('account.plan.read')

      case bearer
      in role: { name: 'admin' | 'developer' | 'sales_agent' | 'support_agent' | 'read_only' }
        allow!
      else
        deny!
      end
    end

    def update?
      verify_permissions!('account.plan.update')

      case bearer
      in role: { name: 'admin' }
        allow!
      else
        deny!
      end
    end
  end
end
