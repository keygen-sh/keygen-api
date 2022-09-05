# frozen_string_literal: true

module Accounts
  class BillingPolicy < ApplicationPolicy
    def show?
      verify_permissions!('account.billing.read')

      case bearer
      in role: { name: 'admin' }
        allow!
      else
        deny!
      end
    end

    def update?
      verify_permissions!('account.billing.update')

      case bearer
      in role: { name: 'admin' }
        allow!
      else
        deny!
      end
    end
  end
end
